<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\OrderItem;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

use App\Traits\ApiResponse;

class ReportController extends Controller
{
    use ApiResponse;
    public function sales(Request $request)
    {
        // Handle 'range' parameter
        $range = $request->query('range', 'week');
        $now = Carbon::now();
        
        if ($range === 'today') {
            $startDate = $now->copy()->startOfDay();
            $endDate = $now->copy()->endOfDay();
        } elseif ($range === 'month') {
            $startDate = $now->copy()->startOfMonth();
            $endDate = $now->copy()->endOfDay();
        } else { // default to week
            $startDate = $now->copy()->startOfWeek();
            $endDate = $now->copy()->endOfDay();
        }

        // Override if explicit dates provided
        if ($request->has('start_date')) {
            $startDate = Carbon::parse($request->query('start_date'));
        }
        if ($request->has('end_date')) {
            $endDate = Carbon::parse($request->query('end_date'))->endOfDay();
        }
        
        // 1. Total Revenue
        $totalRevenue = Order::whereBetween('created_at', [$startDate, $endDate])
            ->where('payment_status', 'paid')
            ->sum('grand_total');

        // 1b. Total Transactions
        $totalTransactions = Order::whereBetween('created_at', [$startDate, $endDate])
            ->where('payment_status', 'paid')
            ->count();
            
        // 2. Gross Profit
        $itemsQuery = OrderItem::whereHas('order', function ($q) use ($startDate, $endDate) {
            $q->whereBetween('created_at', [$startDate, $endDate])
              ->where('payment_status', 'paid');
        });
        
        $totalSalesFromItems = $itemsQuery->sum('total_price');
        $totalCost = $itemsQuery->select(DB::raw('SUM(unit_cost * quantity) as total_cost'))->value('total_cost') ?? 0;
        
        $grossProfit = $totalSalesFromItems - $totalCost;
        
        // 3. Top Products
        $topProducts = OrderItem::whereHas('order', function ($q) use ($startDate, $endDate) {
                $q->whereBetween('created_at', [$startDate, $endDate])
                  ->where('payment_status', 'paid');
            })
            ->join('products', 'order_items.product_id', '=', 'products.id')
            ->select('products.name as product_name', 'order_items.product_id', DB::raw('SUM(order_items.quantity) as quantity_sold'), DB::raw('SUM(order_items.total_price) as total_revenue'))
            ->groupBy('order_items.product_id', 'products.name')
            ->orderByDesc('quantity_sold')
            ->limit(5)
            ->get();

        // 4. Sales Trend (Daily Data for Chart)
        $salesTrendData = Order::whereBetween('created_at', [$startDate, $endDate])
            ->where('payment_status', 'paid')
            ->select(
                DB::raw('DATE(created_at) as date'), 
                DB::raw('SUM(grand_total) as total')
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get()
            ->pluck('total', 'date');

        // Fill in missing dates with 0
        $salesTrend = [];
        $period = \Carbon\CarbonPeriod::create($startDate, $endDate);
        foreach ($period as $date) {
            $dateString = $date->format('Y-m-d');
            $salesTrend[$dateString] = $salesTrendData[$dateString] ?? 0;
        }

        // 5. Staff Performance
        $staffPerformance = Order::whereBetween('orders.created_at', [$startDate, $endDate])
            ->where('orders.payment_status', 'paid')
            ->join('users', 'orders.user_id', '=', 'users.id')
            ->select('users.name as staff_name', DB::raw('COUNT(*) as total_orders'), DB::raw('SUM(orders.grand_total) as total_sales'))
            ->groupBy('orders.user_id', 'users.name')
            ->orderByDesc('total_sales')
            ->get();

        // 6. Payment Methods
        $paymentMethods = Order::whereBetween('created_at', [$startDate, $endDate])
            ->where('payment_status', 'paid')
            ->select('payment_method', DB::raw('COUNT(*) as count'), DB::raw('SUM(grand_total) as total'))
            ->groupBy('payment_method')
            ->get();
            
        return $this->successResponse([
            'period' => [
                'start' => $startDate->toDateString(),
                'end' => $endDate->toDateString(),
            ],
            'total_revenue' => (float) $totalRevenue,
            'total_transactions' => $totalTransactions,
            'gross_profit' => (float) $grossProfit,
            'top_products' => $topProducts,
            'sales_trend' => $salesTrend,
            'staff_performance' => $staffPerformance,
            'payment_methods' => $paymentMethods,
        ]);
    }
}
