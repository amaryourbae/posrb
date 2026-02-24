<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class OneApiService
{
    protected $apiKey;
    // URL not provided, strictly following instructions to use the KEY. 
    // Assuming a standard endpoint or placeholder that can be updated in .env later if distinct from OneSender.
    // If OneSender is the provider, maybe they have a check-number endpoint.
    // Ideally we would ask, but for now we create the structure.
    
    public function __construct()
    {
        $this->apiKey = env('ONEAPI_KEY');
    }

    public function validateNumber($phone)
    {
        // 1. Format Phone to 62...
        $phone = preg_replace('/\D/', '', $phone);
        if (str_starts_with($phone, '0')) {
            $phone = '62' . substr($phone, 1);
        }

        // 2. Call API
        try {
            /** @var \Illuminate\Http\Client\Response $response */
            $response = Http::post('https://oneapi.my.id/api/check-wa', [
                'api_key' => $this->apiKey,
                'phone' => $phone
            ]);

            // 3. Handle Response
            if ($response->successful()) {
                $data = $response->json();
                
                Log::info("OneAPI Check Response: " . json_encode($data));

                if (!($data['success'] ?? false)) {
                    // API Call failed (e.g. invalid key, format)
                    Log::error("OneAPI returned success:false");
                    return false;
                }

                $status = $data['data']['status'] ?? 'unknown';
                
                // Assuming 'on-whatsapp', 'exist', or just NOT 'not-found'
                // Based on curl: {"status":"not-found"} for invalid.
                // We'll consider it valid if it's NOT 'not-found' and NOT 'invalid'
                
                return $status !== 'not-found' && $status !== 'invalid';
            }
            
            Log::error("OneAPI Failed: " . $response->body());
            return false;

        } catch (\Exception $e) {
            Log::error("OneAPI Exception: " . $e->getMessage());
            // Fallback: If API fails, do we block?
            // User wants to avoid spam. Safest to block or return false if we trust the API availability.
            // Or return true to not lose customers?
            // "untuk menghindari spam" -> strict validation implies return false on error, 
            // but for business functionality usually we fail open (return true).
            // However, since this is specific spam prevention, let's return false to force valid number or retry.
            return false;
        }
    }
}
