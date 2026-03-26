<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class OneSenderService
{
    protected $apiUrl;
    protected $apiKey;

    public function __construct()
    {
        $this->apiUrl = env('ONESENDER_API_URL');
        $this->apiKey = env('ONESENDER_API_KEY');
    }

    public function sendMessage($phone, $message)
    {
        // OneSender specific payload structure
        // Assuming standard payload: { "recipient_type": "individual", "to": "628...", "type": "text", "text": { "body": "message" } }
        // Or simple: { "number": "...", "message": "..." }
        // Based on common local gateways, usually strict about formatting.
        
        // Let's assume a generic structure or try to infer. The URL is .../messages.
        // Usually requires Authorization Header.
        
        try {
            // Ensure phone format (62...)
            $phone = $this->formatPhone($phone);

            /** @var \Illuminate\Http\Client\Response $response */
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Content-Type' => 'application/json',
            ])->post($this->apiUrl, [
                'recipient_type' => 'individual',
                'to' => $phone,
                'type' => 'text',
                'text' => [
                    'body' => $message
                ]
            ]);

            if ($response->successful()) {
                Log::info("WhatsApp sent to {$phone}");
                return true;
            } else {
                Log::error("OneSender Error: " . $response->body());
                return false;
            }
        } catch (\Exception $e) {
            Log::error("OneSender Exception: " . $e->getMessage());
            return false;
        }
    }

    public function sendGroupMessage($groupId, $message)
    {
        try {
            /** @var \Illuminate\Http\Client\Response $response */
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Content-Type' => 'application/json',
            ])->post($this->apiUrl, [
                'recipient_type' => 'group',
                'to' => $groupId,
                'type' => 'text',
                'text' => [
                    'body' => $message
                ]
            ]);

            if ($response->successful()) {
                Log::info("WhatsApp group message sent to {$groupId}");
                return true;
            } else {
                Log::error("OneSender Group Error: " . $response->body());
                return false;
            }
        } catch (\Exception $e) {
            Log::error("OneSender Group Exception: " . $e->getMessage());
            return false;
        }
    }

    public function sendGroupImage($groupId, $imageUrl, $caption = '')
    {
        try {
            /** @var \Illuminate\Http\Client\Response $response */
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Content-Type' => 'application/json',
            ])->post($this->apiUrl, [
                'recipient_type' => 'group',
                'to' => $groupId,
                'type' => 'image',
                'image' => [
                    'link' => $imageUrl,
                    'caption' => $caption
                ]
            ]);

            if ($response->successful()) {
                Log::info("WhatsApp group image sent to {$groupId}");
                return true;
            } else {
                Log::error("OneSender Group Image Error: " . $response->body());
                return false;
            }
        } catch (\Exception $e) {
            Log::error("OneSender Group Image Exception: " . $e->getMessage());
            return false;
        }
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
}
