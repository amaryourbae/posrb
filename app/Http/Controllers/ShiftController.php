<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Shift;
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
        $shift = Shift::where('user_id', $request->user()->id)
            ->where('status', 'open')
            ->first();

        if ($shift) {
            // Calculate current cash sales
            $cashSales = Order::where('shift_id', $shift->id)
                ->where('payment_method', 'cash')
                ->where('payment_status', 'paid')
                ->sum('grand_total');

            // Calculate cash refunds
            $cashRefunds = Order::where('shift_id', $shift->id)
                ->where('payment_method', 'cash')
                ->where('payment_status', 'refunded')
                ->sum('grand_total');
            
            $shift->current_cash_sales = (float) $cashSales;
            $shift->current_cash_refunds = (float) $cashRefunds;
            $shift->expected_cash = $shift->starting_cash + $cashSales - $cashRefunds;
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
        $existingShift = Shift::where('user_id', $user->id)
            ->where('status', 'open')
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
        $shift = Shift::where('user_id', $user->id)
            ->where('status', 'open')
            ->first();

        if (!$shift) {
            return $this->errorResponse('No open shift found', 400);
        }


        $cashSales = Order::where('shift_id', $shift->id)
            ->where('payment_method', 'cash')
            ->where('payment_status', 'paid')
            ->sum('grand_total');

        $expected = $shift->starting_cash + $cashSales;
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

        // Calculate Item Breakdown
        $soldItems = DB::table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->join('products', 'order_items.product_id', '=', 'products.id')
            ->where('orders.shift_id', $shift->id)
            ->where('orders.payment_status', 'paid')
            ->select('products.name', DB::raw('SUM(order_items.quantity) as qty'), DB::raw('SUM(order_items.total_price) as total'))
            ->groupBy('products.name')
            ->get();

        // Attach summary to response
        $shift->sales_summary = $soldItems;

        return $this->successResponse($shift, 'Shift ended successfully');
    }

    /**
     * List all shifts (Admin History).
     */
    public function index(Request $request)
    {
        $query = Shift::with('user')->orderBy('created_at', 'desc');

        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->input('date')) {
            $query->whereDate('start_time', $request->date);
        }

        return $this->successResponse($query->paginate(10));
    }
}
