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
            ->where('payment_status', '=', 'paid', 'and')
            ->sum('grand_total');

        // 1b. Total Transactions
        $totalTransactions = Order::whereBetween('created_at', [$startDate, $endDate])
            ->where('payment_status', '=', 'paid', 'and')
            ->count();
            
        // 2. Gross Profit
        $itemsQuery = OrderItem::whereHas('order', function ($q) use ($startDate, $endDate) {
            $q->whereBetween('created_at', [$startDate, $endDate])
              ->where('payment_status', '=', 'paid', 'and');
        });
        
        $totalSalesFromItems = $itemsQuery->sum('total_price');
        $totalCost = $itemsQuery->select(DB::raw('SUM(unit_cost * quantity) as total_cost'))->value('total_cost') ?? 0;
        
        $grossProfit = $totalSalesFromItems - $totalCost;
        
        // 3. Top Products
        $topProducts = OrderItem::whereHas('order', function ($q) use ($startDate, $endDate) {
                $q->whereBetween('created_at', [$startDate, $endDate])
                  ->where('payment_status', '=', 'paid', 'and');
            })
            ->join('products', 'order_items.product_id', '=', 'products.id')
            ->select('products.name as product_name', 'order_items.product_id', DB::raw('SUM(order_items.quantity) as quantity_sold'), DB::raw('SUM(order_items.total_price) as total_revenue'))
            ->groupBy('order_items.product_id', 'products.name')
            ->orderByDesc('quantity_sold')
            ->limit(5)
            ->get();

        // 4. Sales Trend (Daily Data for Chart)
        $salesTrendData = Order::whereBetween('created_at', [$startDate, $endDate])
            ->where('payment_status', '=', 'paid', 'and')
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
            ->where('orders.payment_status', '=', 'paid', 'and')
            ->join('users', 'orders.user_id', '=', 'users.id')
            ->select('users.name as staff_name', DB::raw('COUNT(*) as total_orders'), DB::raw('SUM(orders.grand_total) as total_sales'))
            ->groupBy('orders.user_id', 'users.name')
            ->orderByDesc('total_sales')
            ->get();

        // 6. Payment Methods
        $paymentMethods = Order::whereBetween('created_at', [$startDate, $endDate])
            ->where('payment_status', '=', 'paid', 'and')
            ->select('payment_method', DB::raw('COUNT(*) as count'), DB::raw('SUM(grand_total) as total'))
            ->groupBy('payment_method')
            ->get();

        // 7. Sales per Sales Type Breakdown
        $salesByType = Order::whereBetween('orders.created_at', [$startDate, $endDate])
            ->where('orders.payment_status', '=', 'paid', 'and')
            ->leftJoin('sales_types', 'orders.sales_type_id', '=', 'sales_types.id')
            ->select(
                DB::raw('COALESCE(sales_types.name, "Other/Direct") as type_name'),
                DB::raw('COUNT(*) as total_orders'),
                DB::raw('SUM(orders.grand_total) as total_sales')
            )
            ->groupBy('orders.sales_type_id', 'sales_types.name')
            ->orderByDesc('total_sales')
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
            'sales_by_type' => $salesByType,
        ]);
    }

    public function profitLoss(Request $request)
    {
        $range = $request->query('range', 'month');
        $now = Carbon::now();
        
        if ($range === 'today') {
            $startDate = $now->copy()->startOfDay();
            $endDate = $now->copy()->endOfDay();
        } elseif ($range === 'week') {
            $startDate = $now->copy()->startOfWeek();
            $endDate = $now->copy()->endOfDay();
        } else {
            $startDate = $now->copy()->startOfMonth();
            $endDate = $now->copy()->endOfDay();
        }

        if ($request->has('start_date')) {
            $startDate = Carbon::parse($request->query('start_date'))->startOfDay();
        }
        if ($request->has('end_date')) {
            $endDate = Carbon::parse($request->query('end_date'))->endOfDay();
        }

        $itemsQuery = OrderItem::join('orders', 'order_items.order_id', '=', 'orders.id', 'inner')
            ->whereBetween('orders.created_at', [$startDate, $endDate])
            ->where('orders.payment_status', '=', 'paid', 'and');

        // 1. Totals
        // Rebuild query instance since sum() executes immediately
        $totalRevenue = (float) (clone $itemsQuery)->sum('order_items.total_price');
        $totalCogs = (float) (clone $itemsQuery)->select(DB::raw('SUM(order_items.unit_cost * order_items.quantity) as total_cost'))->value('total_cost') ?? 0;
        $grossProfit = $totalRevenue - $totalCogs;
        $profitMargin = $totalRevenue > 0 ? ($grossProfit / $totalRevenue) * 100 : 0;

        // 2. Daily Trend
        $dailyData = (clone $itemsQuery)
            ->select(
                DB::raw('DATE(orders.created_at) as date'),
                DB::raw('SUM(order_items.total_price) as revenue'),
                DB::raw('SUM(order_items.unit_cost * order_items.quantity) as cogs')
            )
            ->groupBy('date')
            ->orderBy('date')
            ->get()
            ->keyBy('date');

        $trend = [];
        $period = \Carbon\CarbonPeriod::create($startDate, $endDate);
        foreach ($period as $date) {
            $dateString = $date->format('Y-m-d');
            $dayData = $dailyData->get($dateString);
            
            $rev = $dayData ? (float) $dayData->revenue : 0;
            $cogs = $dayData ? (float) $dayData->cogs : 0;
            
            $trend[] = [
                'date' => $dateString,
                'revenue' => $rev,
                'cogs' => $cogs,
                'profit' => $rev - $cogs,
            ];
        }

        // 3. Product Breakdown
        $productBreakdown = (clone $itemsQuery)
            ->join('products', 'order_items.product_id', '=', 'products.id')
            ->select(
                'products.name as product_name',
                'order_items.product_id',
                DB::raw('SUM(order_items.quantity) as quantity_sold'),
                DB::raw('SUM(order_items.total_price) as total_revenue'),
                DB::raw('SUM(order_items.unit_cost * order_items.quantity) as total_cogs')
            )
            ->groupBy('order_items.product_id', 'products.name')
            ->orderByDesc('total_revenue')
            ->get()
            ->map(function ($item) {
                $rev = (float) $item->total_revenue;
                $cogs = (float) $item->total_cogs;
                $profit = $rev - $cogs;
                $margin = $rev > 0 ? ($profit / $rev) * 100 : 0;
                
                return [
                    'product_id' => $item->product_id,
                    'product_name' => $item->product_name,
                    'quantity_sold' => (int) $item->quantity_sold,
                    'total_revenue' => $rev,
                    'total_cogs' => $cogs,
                    'gross_profit' => $profit,
                    'profit_margin' => round($margin, 2),
                ];
            });

        return $this->successResponse([
            'period' => [
                'start' => $startDate->toDateString(),
                'end' => $endDate->toDateString(),
            ],
            'summary' => [
                'total_revenue' => $totalRevenue,
                'total_cogs' => $totalCogs,
                'gross_profit' => $grossProfit,
                'profit_margin' => round($profitMargin, 2),
            ],
            'trend' => $trend,
            'product_breakdown' => $productBreakdown,
        ]);
    }

    /**
     * Get Inventory Transactions (Stock In/Out Report)
     */
    public function inventoryTransactions(Request $request)
    {
        $query = \App\Models\InventoryTransaction::with(['ingredient', 'user'])
            ->orderBy('created_at', 'desc');

        // Apply filters
        if ($request->has('start_date') && $request->start_date != '') {
            $query->whereDate('created_at', '>=', Carbon::parse($request->start_date));
        }
        if ($request->has('end_date') && $request->end_date != '') {
            $query->whereDate('created_at', '<=', Carbon::parse($request->end_date));
        }
        if ($request->has('type') && $request->type !== 'all') {
            $query->where('type', $request->type);
        }

        $transactions = $query->paginate(15);

        // Stats calculation
        $statsQuery = clone $query;
        $stats = [
            'total_in' => (float) (clone $statsQuery)->where('type', 'in')->sum('total_cost'),
            'total_out' => (float) (clone $statsQuery)->where('type', 'out')->sum('total_cost'),
        ];

        return response()->json([
            'data' => $transactions->items(),
            'meta' => [
                'current_page' => $transactions->currentPage(),
                'last_page' => $transactions->lastPage(),
                'per_page' => $transactions->perPage(),
                'total' => $transactions->total(),
            ],
            'stats' => $stats
        ]);
    }

    /**
     * Export Inventory Transactions to CSV
     */
    public function exportInventoryTransactions(Request $request)
    {
        $query = \App\Models\InventoryTransaction::with(['ingredient', 'user'])
            ->orderBy('created_at', 'desc');

        if ($request->has('start_date') && $request->start_date != '') {
            $query->whereDate('created_at', '>=', Carbon::parse($request->start_date));
        }
        if ($request->has('end_date') && $request->end_date != '') {
            $query->whereDate('created_at', '<=', Carbon::parse($request->end_date));
        }
        if ($request->has('type') && $request->type !== 'all') {
            $query->where('type', $request->type);
        }

        $transactions = $query->get();

        $filename = "stock_report_" . now()->format('Y-m-d_His') . ".csv";
        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$filename",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        ];

        $columns = [
            'Tanggal', 'Bahan Baku', 'Tipe', 'Qty', 'Total Nilai', 'Ref/Notes', 'Staff'
        ];

        $callback = function() use($transactions, $columns) {
            $file = fopen('php://output', 'w');
            // Adding BOM for Excel UTF-8 compatibility
            fputs($file, "\xEF\xBB\xBF");
            fputcsv($file, $columns);

            foreach ($transactions as $tx) {
                $row = [
                    $tx->created_at->format('Y-m-d H:i:s'),
                    $tx->ingredient ? $tx->ingredient->name : '-',
                    strtoupper($tx->type),
                    $tx->quantity,
                    $tx->total_cost,
                    ($tx->reference ? $tx->reference . " - " : "") . $tx->notes,
                    $tx->user ? $tx->user->name : 'System'
                ];
                fputcsv($file, $row);
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }
}
