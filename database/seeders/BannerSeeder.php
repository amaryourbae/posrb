<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Banner;

class BannerSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        Banner::create([
            'image_url' => 'https://placehold.co/800x400/004d34/ffffff?text=Welcome+to+POS+RB',
            'title' => 'Welcome to POS RuangBincang',
            'description' => 'Experience the best coffee in town with our premium selection.',
            'action_label' => 'Order Now',
            'action_link' => '/app/order',
            'order' => 1,
            'is_active' => true,
        ]);

        Banner::create([
            'image_url' => 'https://placehold.co/800x400/EDB01D/004d34?text=Weekend+Promo',
            'title' => 'Weekend Promo 50%',
            'description' => 'Get 50% discount on all Pastries this weekend!',
            'action_label' => 'Claim Offer',
            'action_link' => '/app/promo',
            'order' => 2,
            'is_active' => true,
        ]);

        Banner::create([
            'image_url' => 'https://placehold.co/800x400/333333/ffffff?text=New+Menu',
            'title' => 'New Seasonal Beans',
            'description' => 'Try our new Ethiopia Yirgacheffe, roasted to perfection.',
            'action_label' => 'View Menu',
            'action_link' => '/app/order',
            'order' => 3,
            'is_active' => true,
        ]);
    }
}
