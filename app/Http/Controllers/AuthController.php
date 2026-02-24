<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;

use App\Traits\ApiResponse;

class AuthController extends Controller
{
    use ApiResponse;
    public function login(Request $request)
    {
        // 1. WhatsApp OTP Login Flow
        if ($request->has('is_otp') && $request->is_otp) {
            return $this->loginWithOtp($request);
        }

        // 2. Standard Email/Password Login Flow
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($request->only('email', 'password'))) {
            $user = User::with('roles')->find(Auth::id());
            
            $token = $user->createToken('auth_token')->plainTextToken;
            
            \App\Helpers\LogHelper::log('auth.login', "User {$user->name} logged in via Email");

            return $this->successResponse([
                'token' => $token,
                'user' => $user
            ], 'Login successful');
        }

        return $this->errorResponse('Invalid credentials', 401);
    }

    /**
     * Handle OTP Login for Users (Staff/Admin)
     */
    protected function loginWithOtp(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
            'otp' => 'nullable|string', // If null, send OTP. If present, verify.
        ]);

        $phone = $this->formatPhone($request->phone);
        $user = User::where('no_whatsapp', $phone)->first();

        if (!$user) {
            return $this->errorResponse('WhatsApp number not registered in system.', 404);
        }

        // A. If OTP is provided, Verify it
        if ($request->has('otp') && !empty($request->otp)) {
            $cacheKey = "user_otp_{$phone}";
            $cachedOtp = \Illuminate\Support\Facades\Cache::get($cacheKey);

            if (!$cachedOtp || $cachedOtp != $request->otp) {
                 // Backdoor for dev/testing if needed, else strict
                 return response()->json(['message' => 'Invalid or expired OTP'], 400);
            }

            // Login Scucess
            \Illuminate\Support\Facades\Cache::forget($cacheKey);
            Auth::login($user);
            
            $token = $user->createToken('auth_token')->plainTextToken;
            \App\Helpers\LogHelper::log('auth.login_otp', "User {$user->name} logged in via WhatsApp");

            return $this->successResponse([
                'token' => $token,
                'user' => $user->load('roles')
            ], 'Login successful');
        }

        // B. If OTP not provided, Send it
        $otp = rand(100000, 999999);
        $cacheKey = "user_otp_{$phone}";
        \Illuminate\Support\Facades\Cache::put($cacheKey, $otp, now()->addMinutes(5));

        $message = "Kode Login Admin POS Ruang Bincang: *{$otp}*.\n\nJangan berikan kepada siapapun.";
        \App\Jobs\SendWhatsAppNotification::dispatchAfterResponse($phone, $message);

        return $this->successResponse([
            'phone' => $phone,
            'is_otp_sent' => true
        ], 'OTP sent to WhatsApp');
    }

    private function formatPhone($phone)
    {
        $phone = preg_replace('/\D/', '', $phone);
        if (str_starts_with($phone, '0')) {
            $phone = '62' . substr($phone, 1);
        } elseif (str_starts_with($phone, '8')) {
            $phone = '62' . $phone;
        }
        return $phone;
    }

    public function logout(Request $request)
    {
        $user = $request->user();
        $name = $user ? $user->name : 'Unknown';
        
        /** @var \Laravel\Sanctum\PersonalAccessToken $token */
        $token = $user?->currentAccessToken();
        
        $token?->delete();
        
        // Log explicitly using the user object if available, though helper uses Auth::id() it might be cleared by logout?
        // Actually Auth::id() works until the request ends, but token deletion handles API auth. 
        // For safety we log BEFORE deleting token or just rely on helper finding the user via object if we passed it?
        // Helper uses Auth::id(). sanctum user() is available on request. 
        // Actually, currentAccessToken()->delete() revokes it. 
        // Let's rely on Request user being present at this scope.
        
        if ($user) {
             // We need to manually fire log since we might lose auth state context depending on how helper resolves.
             // Helper uses Auth::id(). 
             \App\Models\ActivityLog::create([
                'user_id' => $user->id,
                'action' => 'auth.logout',
                'description' => "User {$name} logged out",
                'ip_address' => $request->ip()
            ]);
        }

        return $this->successResponse(null, 'Logged out successfully');
    }
}
