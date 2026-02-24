<?php

namespace Database\Seeders;

use App\Models\Setting;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class SettingSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $settings = [
            // General
            [
                'key' => 'store_name',
                'value' => 'Fore Coffee Clone',
                'type' => 'string',
                'group' => 'general',
            ],
            [
                'key' => 'store_address',
                'value' => 'Jl. Digital No. 1, Jakarta',
                'type' => 'string',
                'group' => 'general',
            ],
            [
                'key' => 'store_phone',
                'value' => '08123456789',
                'type' => 'string',
                'group' => 'general',
            ],
            
            // Finance
            [
                'key' => 'tax_rate',
                'value' => '11',
                'type' => 'integer',
                'group' => 'finance',
            ],
            [
                'key' => 'service_charge',
                'value' => '0',
                'type' => 'integer',
                'group' => 'finance',
            ],
            
            // Hardware
            [
                'key' => 'printer_connection',
                'value' => 'network',
                'type' => 'string',
                'group' => 'hardware',
            ],
            [
                'key' => 'printer_ip_address',
                'value' => '192.168.1.200',
                'type' => 'string',
                'group' => 'hardware',
            ],
            [
                'key' => 'receipt_footer_text',
                'value' => 'Thank you for shopping with us!',
                'type' => 'string',
                'group' => 'hardware',
            ],
        ];

        foreach ($settings as $setting) {
            Setting::firstOrCreate(
                ['key' => $setting['key']],
                $setting
            );
        }
    }
}
