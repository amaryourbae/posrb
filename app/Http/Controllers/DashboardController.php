<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Models\Ingredient;
use App\Models\Order;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

use App\Traits\ApiResponse;

class DashboardController extends Controller
{
    use ApiResponse;
    /**
     * Get dashboard summary for "Today".
     */
    public function index()
    {
        $today = Carbon::today();
        
        // 1. Total Sales Today (Grand Total of 'completed' or 'paid' orders?)
        // Assuming 'payment_status'='paid' is the key metric for confirmed revenue.
        $totalSalesToday = Order::whereDate('created_at', $today)
            ->where('payment_status', 'paid')
            ->sum('grand_total');
            
        // 2. Transaction Count Today
        $transactionCountToday = Order::whereDate('created_at', $today)
            ->where('payment_status', 'paid')
            ->count();
            
        // 3. Low Stock Count
        $lowStockCount = Ingredient::whereColumn('current_stock', '<=', 'minimum_stock_alert')->count();
        
        // 4. New Members Count (This Month)
        $newMembersCount = Customer::whereMonth('created_at', Carbon::now()->month)
            ->whereYear('created_at', Carbon::now()->year)
            ->count();
            
        // 5. Sales Trend (Last 7 Days)
        $sevenDaysAgo = Carbon::today()->subDays(6);
        $salesTrendData = Order::whereDate('created_at', '>=', $sevenDaysAgo)
            ->where('payment_status', 'paid')
            ->select(
                DB::raw('DATE(created_at) as date'), 
                DB::raw('SUM(grand_total) as total')
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get()
            ->pluck('total', 'date');

        // Fill in missing dates for last 7 days
        $salesTrend = [];
        $period = \Carbon\CarbonPeriod::create($sevenDaysAgo, Carbon::today());
        foreach ($period as $date) {
            $dateString = $date->format('Y-m-d');
            $salesTrend[$dateString] = $salesTrendData[$dateString] ?? 0;
        }

        // 6. Recent Orders (Limit 5)
        $recentOrders = Order::with('customer')
            ->where('payment_status', 'paid')
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        // 7. Popular Items (Top 5 selling products)
        $popularItems = DB::table('order_items')
            ->join('orders', 'orders.id', '=', 'order_items.order_id')
            ->join('products', 'products.id', '=', 'order_items.product_id') // Join products table
            ->leftJoin('categories', 'categories.id', '=', 'products.category_id') // Join categories for category name
            ->where('orders.payment_status', 'paid')
            ->select(
                'products.id',
                'products.name',
                'products.image_url',
                'categories.name as category_name',
                DB::raw('SUM(order_items.quantity) as total_sold')
            )
            ->groupBy('products.id', 'products.name', 'products.image_url', 'categories.name')
            ->orderByDesc('total_sold')
            ->limit(5)
            ->get();
            
        return $this->successResponse([
            'total_sales_today' => (float) $totalSalesToday,
            'transaction_count_today' => $transactionCountToday,
            'low_stock_count' => $lowStockCount,
            'new_members_count' => $newMembersCount,
            'sales_trend' => $salesTrend,
            'recent_orders' => $recentOrders,
            'popular_items' => $popularItems,
            'date' => $today->toDateString(),
        ]);
    }
    /**
     * Get specific stats for POS Dashboard (Cashier View).
     */
    public function posStats(Request $request) 
    {
        $user = $request->user();
        $today = Carbon::today();

        // 1. My Sales Today (Paid)
        $mySalesToday = Order::where('user_id', $user->id)
            ->whereDate('created_at', $today)
            ->where('payment_status', 'paid')
            ->sum('grand_total');

        // 2. My Transaction Count Today
        $myTransactionCount = Order::where('user_id', $user->id)
            ->whereDate('created_at', $today)
            ->where('payment_status', 'paid')
            ->count();

        // 3. Pending Orders (Global - relevant for queue)
        $pendingCount = Order::where('payment_status', 'pending')
            ->count();
        
        // 4. Low Stock Count (Global)
        $lowStockCount = Ingredient::whereColumn('current_stock', '<=', 'minimum_stock_alert')->count();

        return $this->successResponse([
            'today_sales' => (float) $mySalesToday,
            'transaction_count' => $myTransactionCount,
            'pending_count' => $pendingCount,
            'low_stock_count' => $lowStockCount,
        ]);
    }
}
