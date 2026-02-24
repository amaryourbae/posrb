<?php

namespace Database\Seeders;

use App\Models\Discount;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class DiscountSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        Discount::truncate();

        Discount::create([
            'name' => 'FORE More Sips - Diskon 90%',
            'code' => 'FORE90',
            'type' => 'percentage',
            'value' => 90, // 90%
            'min_purchase' => 0,
            'start_date' => Carbon::now(),
            'end_date' => '2026-01-30 23:59:59',
            'is_active' => true,
        ]);

        Discount::create([
            'name' => 'Treats FOREveryday! Diskon 10%',
            'code' => 'TREATS10',
            'type' => 'percentage',
            'value' => 10,
            'min_purchase' => 15000,
            'start_date' => Carbon::now(),
            'end_date' => '2026-12-31 23:59:59',
            'is_active' => true,
        ]);

        Discount::create([
            'name' => 'Potongan Rp 10.000',
            'code' => 'HEMAT10K',
            'type' => 'fixed',
            'value' => 10000,
            'min_purchase' => 50000,
            'start_date' => Carbon::now(),
            'end_date' => '2026-06-30 23:59:59',
            'is_active' => true,
        ]);
        
        Discount::create([
             'name' => 'Gratis Ongkir (Expired)',
             'code' => 'ONGKIR0',
             'type' => 'fixed',
             'value' => 5000,
             'min_purchase' => 0,
             'start_date' => '2024-01-01 00:00:00',
             'end_date' => '2024-01-31 23:59:59',
             'is_active' => true, // Active but expired
         ]);

        // Create 10 more dummy vouchers
        for ($i = 1; $i <= 10; $i++) {
            Discount::create([
                'name' => 'Voucher Spesial #' . $i,
                'code' => 'PROMO' . $i,
                'type' => rand(0, 1) ? 'percentage' : 'fixed',
                'value' => rand(0, 1) ? rand(10, 50) : rand(5000, 20000),
                'min_purchase' => rand(20000, 100000),
                'start_date' => Carbon::now(),
                'end_date' => Carbon::now()->addDays(rand(7, 30)),
                'is_active' => true,
            ]);
        }
    }
}
