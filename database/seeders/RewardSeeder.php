<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Reward;
use App\Models\Product;

class RewardSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Ensure products exist or use placeholders if specific IDs needed
        
        $kopiRuang = Product::query()->where(fn($q) => $q->where('name', 'like', '%Kopi Ruang%', 'and'), null, null, 'and')->first(['*']);
        $butterscotch = Product::query()->where(fn($q) => $q->where('name', 'like', '%Butterscotch%', 'and'), null, null, 'and')->first(['*']);
        $americano = Product::query()->where(fn($q) => $q->where('name', 'like', '%Americano%', 'and'), null, null, 'and')->first(['*']);

        $rewards = [
            [
                'name' => 'Free Kopi Ruang',
                'description' => 'Nikmati Kopi Ruang gratis dengan menukarkan poinmu.',
                'image_url' => $kopiRuang ? $kopiRuang->image_url : null,
                'point_cost' => 50,
                'type' => 'free_product',
                'product_id' => $kopiRuang?->id,
                'is_active' => true,
            ],
            [
                'name' => 'Free Butterscotch Sea Salt',
                'description' => 'Sensasi manis gurih Butterscotch gratis untukmu.',
                'image_url' => $butterscotch ? $butterscotch->image_url : null,
                'point_cost' => 70,
                'type' => 'free_product',
                'product_id' => $butterscotch?->id,
                'is_active' => true,
            ],
            [
                'name' => 'Free Americano',
                'description' => 'Boost energii dengan segelas Americano.',
                'image_url' => $americano ? $americano->image_url : null,
                'point_cost' => 48,
                'type' => 'free_product',
                'product_id' => $americano?->id,
                'is_active' => true,
            ]
        ];

        foreach ($rewards as $data) {
            if ($data['product_id']) {
                Reward::firstOrCreate(
                    ['name' => $data['name']],
                    $data
                );
            }
        }
    }
}
