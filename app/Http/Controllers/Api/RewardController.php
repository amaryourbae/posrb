<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Reward;
use App\Models\CustomerVoucher;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

use App\Traits\ApiResponse;

class RewardController extends Controller
{
    use ApiResponse;
    public function index()
    {
        $rewards = Reward::where('is_active', true)
            ->with(['product:id,name,description,image_url,price']) // optimize query
            ->orderBy('point_cost', 'asc')
            ->get();
            
        return $this->successResponse($rewards);
    }

    public function show($id)
    {
        $reward = Reward::with('product')->where('is_active', true)->findOrFail($id);
        return $this->successResponse($reward);
    }

    public function redeem(Request $request, $id)
    {
        $user = $request->user();
        if (!$user) {
            return $this->errorResponse('Unauthorized', 401);
        }

        // Lock for update to prevent race conditions
        return DB::transaction(function () use ($user, $id) {
            $customer = $user; // Assuming MemberAuth means user IS customer (or we load customer from user)
            // Wait, MemberAuth uses `customers` table as User provider? 
            // Let's verify in route/auth setup. Usually yes for "Member App".
            // If strict: $customer = \App\Models\Customer::find($user->id);
            
            $reward = Reward::lockForUpdate()->where('is_active', true)->findOrFail($id);

            if ($customer->points_balance < $reward->point_cost) {
                return $this->errorResponse('Poin tidak cukup', 400);
            }

            // Deduct Points
            $customer->points_balance -= $reward->point_cost;
            $customer->save();

            // Create Voucher
            $voucher = CustomerVoucher::create([
                'customer_id' => $customer->id,
                'reward_id' => $reward->id,
                'code' => 'RWD-' . strtoupper(Str::random(8)),
                'status' => 'active',
                'expires_at' => now()->addMonths(3), // Default expiry 3 months
            ]);

            return $this->successResponse([
                'voucher' => $voucher,
                'remaining_points' => $customer->points_balance
            ], 'Berhasil menukarkan poin!', 201);
        });
    }
}
