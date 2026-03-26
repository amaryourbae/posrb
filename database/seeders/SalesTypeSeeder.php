<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\SalesType;

class SalesTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $types = [
            [
                'name' => 'Dine In',
                'slug' => 'dine_in',
                'is_active' => true,
                'sort_order' => 1,
            ],
            [
                'name' => 'Pickup',
                'slug' => 'pickup',
                'is_active' => true,
                'sort_order' => 2,
            ],
            [
                'name' => 'GoFood',
                'slug' => 'gofood',
                'is_active' => true,
                'sort_order' => 3,
            ],
            [
                'name' => 'GrabFood',
                'slug' => 'grabfood',
                'is_active' => true,
                'sort_order' => 4,
            ],
            [
                'name' => 'ShopeeFood',
                'slug' => 'shopeefood',
                'is_active' => true,
                'sort_order' => 5,
            ],
        ];

        foreach ($types as $type) {
            SalesType::updateOrCreate(
                ['slug' => $type['slug']],
                $type
            );
        }
    }
}
