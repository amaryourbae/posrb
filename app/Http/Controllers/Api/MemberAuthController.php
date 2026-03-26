<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

use App\Traits\ApiResponse;

class MemberAuthController extends Controller
{
    use ApiResponse;
    /**
     * Send OTP to WhatsApp
     */
    public function sendOtp(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
        ]);

        $phone = $this->formatPhone($request->phone);
        
        // Generate 6-digit OTP
        $otp = rand(100000, 999999);
        
        // Store in Cache (5 minutes)
        $cacheKey = "otp_{$phone}";
        Cache::put($cacheKey, $otp, now()->addMinutes(5));

        // Dispatch Job to send WhatsApp
        // Using existing helper logic
        $message = "Kode OTP Ruang Bincang Anda adalah: *{$otp}*.\n\nJangan berikan kode ini kepada siapapun.";
        \App\Jobs\SendWhatsAppNotification::dispatch($phone, $message);

        // For Dev/Debug: log it
        Log::info("OTP for {$phone}: {$otp}");

        return $this->successResponse([
            'phone' => $phone,
        ], 'OTP sent successfully');
    }

    /**
     * Verify OTP and Login
     */
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
            'otp' => 'required|string',
        ]);

        $phone = $this->formatPhone($request->phone);
        $enteredOtp = $request->otp;
        
        $cacheKey = "otp_{$phone}";
        $cachedOtp = Cache::get($cacheKey);

        if (!$cachedOtp || $cachedOtp != $enteredOtp) {
            return $this->errorResponse('Invalid or expired OTP', 400);
        }

        // Find Customer
        $customer = Customer::where('phone', $phone)->first();

        // If not found, return error (this is login endpoint)
        if (!$customer) {
            return $this->errorResponse('Phone number not registered', 404, ['need_register' => true]);
        }

        // Generate Token
        // Clear OTP
        Cache::forget($cacheKey);

        $token = $customer->createToken('member_token')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'user' => $customer
        ], 'Login successful');
    }

    /**
     * Register new member
     */
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|unique:customers,phone',
            'email' => 'nullable|email|unique:customers,email',
            'birth_date' => 'nullable|date',
            // 'otp' => 'required' ? OR re-verify? 
            // Plan: Registration sends OTP first. 
            // So we need "Register Step 1 (Send OTP)" and "Register Step 2 (Verify & Create)"
            // Actually, frontend can just use "sendOtp" for both.
            // But we need to know if we should CREATE or just LOG IN.
            // Let's assume Register flow is:
            // 1. User fills form.
            // 2. Hits "Send OTP". System checks if phone taken. If not, sends OTP.
            // 3. User enters OTP. Hits "Verify".
            // 4. System verifies OTP. Creates Account. Logs in.
        ]);
        
        // This endpoint should be "Verify OTP AND Create Account"
        // But validation above requires 'otp'.
    }
    
    /**
     * Handle Registration Verification & Creation
     */
    public function verifyRegister(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|unique:customers,phone', 
            'otp' => 'required|string',
            'email' => 'nullable|email|unique:customers,email',
            'birth_date' => 'nullable|date',
        ]);

        $phone = $this->formatPhone($request->phone);
        $enteredOtp = $request->otp;
        
        $cacheKey = "otp_{$phone}";
        $cachedOtp = Cache::get($cacheKey);

        if (!$cachedOtp || $cachedOtp != $enteredOtp) {
             // Allow magic OTP for testing?
             if ($enteredOtp !== '123456') {
                 return $this->errorResponse('Invalid or expired OTP', 400);   
             }
        }

        // Create Customer
        $customer = Customer::create([
            'name' => $request->name,
            'phone' => $phone,
            'email' => $request->email,
            'birth_date' => $request->birth_date,
            'points_balance' => 0,
        ]);

        Cache::forget($cacheKey);
        
        $token = $customer->createToken('member_token')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'user' => $customer
        ], 'Registration successful', 201);
    }
    
    // Check if phone available (step 1 of register)
    public function checkPhoneAvailability(Request $request) {
        $request->validate(['phone' => 'required']);
        $phone = $this->formatPhone($request->phone);
        
        
        $exists = Customer::where('phone', $phone)->exists();
        if ($exists) {
            return $this->errorResponse('Phone number already registered', 422);
        }
        
        // If available, send OTP
        return $this->sendOtp($request);
    }

    /**
     * Handle Social Login (Google / Apple)
     */
    public function socialLogin(Request $request)
    {
        $request->validate([
            'provider' => 'required|in:google,apple',
            'token' => 'required|string',
            'email' => 'nullable|email', // Apple sometimes doesn't send email on every login
            'name' => 'nullable|string',
        ]);

        $provider = $request->provider;
        $providerId = null;
        $email = $request->email;
        $name = $request->name;

        try {
            if ($provider === 'google') {
                $client = new \Google\Client(['client_id' => config('services.google.client_id')]);
                $payload = $client->verifyIdToken($request->token);
                if ($payload) {
                    $providerId = $payload['sub'];
                    $email = $payload['email'];
                    $name = $name ?? $payload['name'];
                } else {
                    return $this->errorResponse('Invalid Google Token', 400);
                }
            } else if ($provider === 'apple') {
                 $providerId = $request->token; 
                 $tokenParts = explode(".", $request->token);
                 if (count($tokenParts) === 3) {
                     $payload = json_decode(base64_decode($tokenParts[1]), true);
                     if (isset($payload['sub'])) {
                         $providerId = $payload['sub'];
                     }
                     if (isset($payload['email'])) {
                         $email = $payload['email'];
                     }
                 }
                 
                 if (!$providerId) {
                     return $this->errorResponse('Invalid Apple Token', 400);
                 }
            }

            // Find existing user by provider_id
            $customer = Customer::where('provider_name', $provider)
                                ->where('provider_id', $providerId)
                                ->first();

            // If not found by provider_id, check by email to link accounts
            if (!$customer && $email) {
                 $customer = Customer::where('email', $email)->first();
                 if ($customer) {
                     // Link account
                     $customer->update([
                         'provider_name' => $provider,
                         'provider_id' => $providerId
                     ]);
                 }
            }

            // If still not found, create new customer
            if (!$customer) {
                // If name is missing from provider (e.g. Apple subsequent logins), provide fallback
                $customerName = $name ?? explode('@', $email)[0] ?? 'User';
                
                $customer = Customer::create([
                    'name' => $customerName,
                    'email' => $email, // email could be null
                    'provider_name' => $provider,
                    'provider_id' => $providerId,
                    'points_balance' => 0,
                    // phone is nullable now
                ]);
            }

            // Generate Token
            $token = $customer->createToken('member_token')->plainTextToken;

            return $this->successResponse([
                'token' => $token,
                'user' => $customer
            ], 'Login successful');

        } catch (\Exception $e) {
            Log::error('Social Login Error: ' . $e->getMessage());
            return $this->errorResponse('Authentication failed: ' . $e->getMessage(), 500);
        }
    }

    public function logout(Request $request)
    {
        if ($token = $request->user()->currentAccessToken()) {
            /** @var \Laravel\Sanctum\PersonalAccessToken $token */
            if (method_exists($token, 'delete')) {
                $token->delete();
            }
        }
        
        return $this->successResponse(null, 'Logged out successfully');
    }

    public function me(Request $request)
    {
        return $this->successResponse($request->user());
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();
        
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'nullable|email|max:255|unique:customers,email,' . $user->id,
        ]);

        $user->update([
            'name' => $request->name,
            'email' => $request->email,
        ]);

        return $this->successResponse($user);
    }

    public function orders(Request $request)
    {
        $orders = \App\Models\Order::with('items.product')
            ->where('customer_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();
            
        return $this->successResponse($orders);
    }

    public function showOrder(Request $request, $id)
    {
        $order = \App\Models\Order::with(['items.product']) // Modifiers are a column, not relation
            ->where('customer_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();
            
        return $this->successResponse($order);
    }

    private function formatPhone($phone)
    {
        $phone = preg_replace('/\D/', '', $phone);
        // If starts with 0, replace with 62. e.g. 0812 -> 62812
        if (str_starts_with($phone, '0')) {
            $phone = '62' . substr($phone, 1);
        }
        // If starts with 8, prepend 62. e.g. 812 -> 62812
        elseif (str_starts_with($phone, '8')) {
            $phone = '62' . $phone;
        }
        return $phone;
    }
}
