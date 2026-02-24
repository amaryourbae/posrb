<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomerVoucher;
use Illuminate\Http\Request;

use App\Traits\ApiResponse;

class CustomerVoucherController extends Controller
{
    use ApiResponse;
    public function index(Request $request)
    {
        $user = $request->user();
        
        $vouchers = CustomerVoucher::where('customer_id', $user->id)
            ->with(['reward.product'])
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->successResponse($vouchers);
    }

    public function show(Request $request, $id)
    {
        $user = $request->user();

        $voucher = CustomerVoucher::where('customer_id', $user->id)
            ->with(['reward.product'])
            ->findOrFail($id);

        return $this->successResponse($voucher);
    }
}
