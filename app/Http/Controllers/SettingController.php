<?php

namespace App\Http\Controllers;

use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

use App\Traits\ApiResponse;

class SettingController extends Controller
{
    use ApiResponse;
    /**
     * Get all settings.
     */
    public function index()
    {
        // Cache settings forever until updated
        $settings = Cache::rememberForever('app_settings', function () {
            return Setting::all()
                ->whereNotNull('value')
                ->filter(function ($setting) {
                    return $setting->value !== '';
                })
                ->pluck('value', 'key');
        });

        return $this->successResponse($settings);
    }

    /**
     * Update settings.
     */
    public function update(Request $request)
    {
        $input = $request->except(['_method', 'image']); // Exclude non-setting fields if any

        foreach ($input as $key => $value) {
            // Handle File Uploads (Expect keys like 'banner_1', 'logo', etc.)
            if ($request->hasFile($key)) {
                $path = $request->file($key)->store('settings', 'public');
                $value = \Illuminate\Support\Facades\Storage::url($path);
            }

            // Update or Create the setting
            Setting::updateOrCreate(
                ['key' => $key],
                [
                    'value' => $value,
                    'group' => 'pos' // Default group for settings created via this endpoint
                ]
            );
        }
        
        // Clear cache
        Cache::forget('app_settings');

        $data = Setting::all()
            ->whereNotNull('value')
            ->filter(fn($s) => $s->value !== '')
            ->pluck('value', 'key');
        
        return $this->successResponse($data, 'Settings updated successfully');
    }
}
