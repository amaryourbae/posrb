<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Shift;
use App\Models\CashMovement;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

use App\Traits\ApiResponse;

class ShiftController extends Controller
{
    use ApiResponse;
    /**
     * Get current open shift for logged in user.
     */
    public function current(Request $request)
    {
        $shift = Shift::where('user_id', '=', $request->user()->id, 'and')
            ->where('status', '=', 'open', 'and')
            ->first();

        if ($shift) {
            // Calculate current cash sales
            $cashSales = Order::where('shift_id', '=', $shift->id, 'and')
                ->where('payment_method', '=', 'cash', 'and')
                ->where('payment_status', '=', 'paid', 'and')
                ->sum('grand_total');

            // Calculate cash refunds
            $cashRefunds = Order::where('shift_id', '=', $shift->id, 'and')
                ->where('payment_method', '=', 'cash', 'and')
                ->where('payment_status', '=', 'refunded', 'and')
                ->sum('grand_total');
            // Calculate cash movements
            $payIns = CashMovement::where('shift_id', '=', $shift->id, 'and')->where('type', '=', 'pay_in', 'and')->sum('amount');
            $payOuts = CashMovement::where('shift_id', '=', $shift->id, 'and')->whereIn('type', ['pay_out', 'drop'])->sum('amount');

            $shift->current_cash_sales = (float) $cashSales;
            $shift->current_cash_refunds = (float) $cashRefunds;
            $shift->pay_ins = (float) $payIns;
            $shift->pay_outs = (float) $payOuts;
            $shift->expected_cash = $shift->starting_cash + $cashSales - $cashRefunds + $payIns - $payOuts;

            // Calculate Item Breakdown - Sold
            $soldItems = DB::table('order_items')
                ->join('orders', 'order_items.order_id', '=', 'orders.id')
                ->where('orders.shift_id', '=', $shift->id, 'and')
                ->whereIn('orders.payment_status', ['paid', 'processing'])
                ->select('order_items.product_name as name', DB::raw('SUM(order_items.quantity) as qty'), DB::raw('SUM(order_items.total_price) as total'))
                ->groupBy('order_items.product_name')
                ->get();

            // Calculate Item Breakdown - Refunded
            $refundedItems = DB::table('order_items')
                ->join('orders', 'order_items.order_id', '=', 'orders.id')
                ->where('orders.shift_id', '=', $shift->id, 'and')
                ->where('orders.payment_status', '=', 'refunded', 'and')
                ->select('order_items.product_name as name', DB::raw('SUM(order_items.quantity) as qty'), DB::raw('SUM(order_items.total_price) as total'))
                ->groupBy('order_items.product_name')
                ->get();

            $shift->sales_summary = $soldItems;
            $shift->refunded_items = $refundedItems;
            $shift->items = [
                'sold' => $soldItems,
                'refunded' => $refundedItems,
                'total_sold_qty' => $soldItems->sum('qty'),
                'total_refunded_qty' => $refundedItems->sum('qty'),
            ];
        }

        return $this->successResponse($shift);
    }

    /**
     * Start a new shift.
     */
    public function start(Request $request)
    {
        $request->validate([
            'starting_cash' => 'required|numeric|min:0',
        ]);

        $user = $request->user();

        // Check if already has open shift
        $existingShift = Shift::where('user_id', '=', $user->id, 'and')
            ->where('status', '=', 'open', 'and')
            ->first();

        if ($existingShift) {
            return $this->errorResponse('You already have an open shift', 400);
        }

        $shift = Shift::create([
            'user_id' => $user->id,
            'start_time' => now(),
            'starting_cash' => $request->starting_cash,
            'status' => 'open',
        ]);

        return $this->successResponse($shift, 'Shift started successfully', 201);
    }

    /**
     * End current shift.
     */
    public function end(Request $request)
    {
        $request->validate([
            'ending_cash_actual' => 'required|numeric|min:0',
            'note' => 'nullable|string',
        ]);

        $user = $request->user();
        $shift = Shift::where('user_id', '=', $user->id, 'and')
            ->where('status', '=', 'open', 'and')
            ->first();

        if (!$shift) {
            return $this->errorResponse('No open shift found', 400);
        }


        $cashSales = Order::where('shift_id', '=', $shift->id, 'and')
            ->where('payment_method', '=', 'cash', 'and')
            ->where('payment_status', '=', 'paid', 'and')
            ->sum('grand_total');
            
        $cashRefunds = Order::where('shift_id', $shift->id)
            ->where('payment_method', '=', 'cash', 'and')
            ->where('payment_status', '=', 'refunded', 'and')
            ->sum('grand_total');

        $payIns = CashMovement::where('shift_id', '=', $shift->id, 'and')->where('type', '=', 'pay_in', 'and')->sum('amount');
        $payOuts = CashMovement::where('shift_id', '=', $shift->id, 'and')->whereIn('type', ['pay_out', 'drop'])->sum('amount');

        $expected = $shift->starting_cash + $cashSales - $cashRefunds + $payIns - $payOuts;
        $actual = $request->ending_cash_actual;
        $diff = $actual - $expected;

        $shift->update([
            'end_time' => now(),
            'ending_cash_expected' => $expected,
            'ending_cash_actual' => $actual,
            'difference' => $diff,
            'status' => 'closed',
            'note' => $request->note,
        ]);

        // Calculate Item Breakdown - Sold
        $soldItems = DB::table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->where('orders.shift_id', '=', $shift->id, 'and')
            ->whereIn('orders.payment_status', ['paid', 'processing'])
            ->select('order_items.product_name as name', DB::raw('SUM(order_items.quantity) as qty'), DB::raw('SUM(order_items.total_price) as total'))
            ->groupBy('order_items.product_name')
            ->get();

        // Calculate Item Breakdown - Refunded
        $refundedItems = DB::table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->where('orders.shift_id', '=', $shift->id, 'and')
            ->where('orders.payment_status', '=', 'refunded', 'and')
            ->select('order_items.product_name as name', DB::raw('SUM(order_items.quantity) as qty'), DB::raw('SUM(order_items.total_price) as total'))
            ->groupBy('order_items.product_name')
            ->get();

        // Cash Movements Detail
        $cashMovements = CashMovement::where('shift_id', '=', $shift->id, 'and')
            ->orderBy('created_at', 'asc')
            ->get();

        // Attach summary to response
        $shift->sales_summary = $soldItems;
        $shift->refunded_items = $refundedItems;
        $shift->items = [
            'sold' => $soldItems,
            'refunded' => $refundedItems,
            'total_sold_qty' => $soldItems->sum('qty'),
            'total_refunded_qty' => $refundedItems->sum('qty'),
        ];
        $shift->cash_movements_detail = $cashMovements;
        $shift->pay_ins = (float) $payIns;
        $shift->pay_outs = (float) $payOuts;

        return $this->successResponse($shift, 'Shift ended successfully');
    }

    /**
     * List all shifts (Admin History).
     */
    public function index(Request $request)
    {
        $query = Shift::with('user', 'cashMovements')->orderBy('created_at', 'desc');

        if ($request->has('user_id')) {
            $query->where('user_id', '=', $request->user_id, 'and');
        }

        if ($request->input('date')) {
            $query->whereDate('start_time', $request->date);
        }

        return $this->successResponse($query->paginate(10));
    }

    /**
     * Record a cash movement (pay in/out/drop)
     */
    public function movement(Request $request)
    {
        $request->validate([
            'type' => 'required|in:pay_in,pay_out,drop',
            'amount' => 'required|numeric|min:1',
            'reason' => 'nullable|string'
        ]);

        $user = $request->user();
        $shift = Shift::where('user_id', '=', $user->id, 'and')
            ->where('status', '=', 'open', 'and')
            ->first();

        if (!$shift) {
            return $this->errorResponse('No open shift found', 400);
        }

        $movement = CashMovement::create([
            'shift_id' => $shift->id,
            'type' => $request->type,
            'amount' => $request->amount,
            'reason' => $request->reason,
        ]);

        return $this->successResponse($movement, 'Cash movement recorded');
    }
    /**
     * Show detailed breakdown of a specific shift.
     */
    public function show($id, Request $request)
    {
        $shift = Shift::with(['user', 'cashMovements' => function($q) {
            $q->orderBy('created_at', 'desc');
        }])->findOrFail($id);

        // Calculate Cash Sales (amount_paid from cash orders)
        $cashSales = Order::where('shift_id', '=', $shift->id, 'and')
            ->where('payment_method', '=', 'cash', 'and')
            ->whereIn('payment_status', ['paid', 'processing'])
            ->sum('amount_paid');

        // Note: Change is already deducted physically from the drawer when returning it to customer. 
        // So Cash Sales to drawer = amount_paid - change = grand_total. Let's use grand_total of cash orders.
        $cashSales = Order::where('shift_id', '=', $shift->id, 'and')
            ->where('payment_method', '=', 'cash', 'and')
            ->whereIn('payment_status', ['paid', 'processing'])
            ->sum('grand_total');

        // Cash from Invoices (Typically B2B pay later, assume 0 for POS)
        $cashFromInvoice = 0;

        // Cash Refunds
        $cashRefunds = Order::where('shift_id', $shift->id)
            ->where('payment_method', '=', 'cash', 'and')
            ->where('payment_status', '=', 'refunded', 'and')
            ->sum('grand_total');

        // Expenses (Pay Out & Drop)
        $totalExpense = CashMovement::where('shift_id', '=', $shift->id, 'and')
            ->whereIn('type', ['pay_out', 'drop'])
            ->sum('amount');

        // Income (Pay In)
        $totalIncome = CashMovement::where('shift_id', '=', $shift->id, 'and')
            ->where('type', '=', 'pay_in', 'and')
            ->sum('amount');

        $startingCash = $shift->starting_cash;
        
        $expectedEndingCash = $startingCash + $cashSales + $cashFromInvoice + $totalIncome - $cashRefunds - $totalExpense;
        $actualEndingCash = $shift->ending_cash_actual ?? 0;
        
        // Items Breakdown
        $soldItems = DB::table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->where('orders.shift_id', '=', $shift->id, 'and')
            ->whereIn('orders.payment_status', ['paid', 'processing'])
            ->select('order_items.product_name as name', DB::raw('SUM(order_items.quantity) as qty'), DB::raw('SUM(order_items.total_price) as total'))
            ->groupBy('order_items.product_name')
            ->get();

        $refundedItems = DB::table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->where('orders.shift_id', '=', $shift->id, 'and')
            ->where('orders.payment_status', '=', 'refunded', 'and')
            ->select('order_items.product_name as name', DB::raw('SUM(order_items.quantity) as qty'), DB::raw('SUM(order_items.total_price) as total'))
            ->groupBy('order_items.product_name')
            ->get();

        $detail = [
            'id' => $shift->id,
            'user' => $shift->user->name ?? 'Unknown',
            'start_time' => $shift->start_time,
            'end_time' => $shift->end_time,
            'status' => $shift->status,
            'note' => $shift->note,
            'financials' => [
                'starting_cash' => (float)$startingCash,
                'cash_sales' => (float)$cashSales,
                'cash_from_invoice' => (float)$cashFromInvoice,
                'cash_refunds' => (float)$cashRefunds,
                'total_expense' => (float)$totalExpense,
                'total_income' => (float)$totalIncome,
                'expected_ending_cash' => (float)$expectedEndingCash,
                'actual_ending_cash' => (float)$actualEndingCash,
                'expected_cash_payment' => (float)($cashSales - $cashRefunds), // Sales minus refunds
                'difference' => (float)($actualEndingCash - $expectedEndingCash),
            ],
            'items' => [
                'sold' => $soldItems,
                'refunded' => $refundedItems,
                'total_sold_qty' => (int)$soldItems->sum('qty'),
                'total_refunded_qty' => (int)$refundedItems->sum('qty'),
            ],
            'sales_summary' => $soldItems,
            'refunded_items' => $refundedItems,
            'movements' => $shift->cashMovements,
        ];

        return $this->successResponse($detail);
    }
}
