<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;

class AppVersionController extends Controller
{
    use ApiResponse;

    public function index()
    {
        // In a real app, these values might come from a database or config file
        $data = [
            'android' => [
                'latest_version' => '1.0.2',
                'min_version'    => '1.0.0',
                'url'            => 'https://play.google.com/store/apps/details?id=com.ruangbincang.pos',
            ],
            'ios' => [
                'latest_version' => '1.0.5',
                'min_version'    => '1.0.0',
                'url'            => 'https://apps.apple.com/app/id123456789',
            ],
            'force_update' => false, // Global flag or logic based on user agent
            'message'      => 'New update available with performance improvements.',
        ];

        return $this->successResponse($data, 'App version info retrieved successfully');
    }
}
