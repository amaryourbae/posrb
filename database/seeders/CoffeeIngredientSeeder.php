<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Ingredient;

class CoffeeIngredientSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $user = \App\Models\User::first(['*']) ?? \App\Models\User::factory()->create();

        $ingredients = [
            // Coffee Beans
            ['name' => 'Robusta Beans', 'unit' => 'gram', 'cost' => 300, 'stock' => 1000], // 150k/kg
            ['name' => 'Blend Beans', 'unit' => 'gram', 'cost' => 180, 'stock' => 1000], // 250k/kg
            
            // Liquid & Dairy
            ['name' => 'Fresh Milk', 'unit' => 'ml', 'cost' => 18, 'stock' => 5000], // 18k/L
            ['name' => 'Mineral Water', 'unit' => 'ml', 'cost' => 2, 'stock' => 19000], // 38k/Galon(19L) -> 2/ml
            
            // Syrups & Sweeteners
            ['name' => 'Gula Pasir', 'unit' => 'gram', 'cost' => 16, 'stock' => 1000], // 16k/kg
            ['name' => 'Gula Aren', 'unit' => 'gram', 'cost' => 25, 'stock' => 1000],
            ['name' => 'Himalayan Salt', 'unit' => 'gram', 'cost' => 50, 'stock' => 500],
            
            // Premium Syrups (User Request)
            ['name' => 'Sirup Peach', 'unit' => 'ml', 'cost' => 151.32, 'stock' => 760], // 115k/760ml
            ['name' => 'Sirup Lychee', 'unit' => 'ml', 'cost' => 151.32, 'stock' => 760],
            ['name' => 'Sirup Caramel', 'unit' => 'ml', 'cost' => 130, 'stock' => 750], // ~100k/750ml
            ['name' => 'Sirup Vanilla', 'unit' => 'ml', 'cost' => 130, 'stock' => 750],
            ['name' => 'Sirup Hazelnut', 'unit' => 'ml', 'cost' => 130, 'stock' => 750],
            ['name' => 'Juice Orange', 'unit' => 'ml', 'cost' => 41.51, 'stock' => 960], 
            
            // Powders
            ['name' => 'Chocolate Powder', 'unit' => 'gram', 'cost' => 120, 'stock' => 1000], // 120k/kg
            ['name' => 'Matcha Powder', 'unit' => 'gram', 'cost' => 300, 'stock' => 1000], // 300k/kg
            
            // Consumables
            ['name' => 'Es Batu', 'unit' => 'gram', 'cost' => 1, 'stock' => 10000], // Self production? 
            ['name' => 'Plastic Cup 12oz', 'unit' => 'pcs', 'cost' => 350, 'stock' => 100],
            ['name' => 'Plastic Cup 16oz', 'unit' => 'pcs', 'cost' => 500, 'stock' => 100],
            ['name' => 'Plastic Cup 22oz', 'unit' => 'pcs', 'cost' => 700, 'stock' => 100],
            ['name' => 'Straw', 'unit' => 'pcs', 'cost' => 50, 'stock' => 500],
            ['name' => 'Cup Sealer', 'unit' => 'pcs', 'cost' => 20, 'stock' => 1000],
            
            // Overheads (Unit: pcs/portion)
            ['name' => 'Overhead Listrik', 'unit' => 'pcs', 'cost' => 200, 'stock' => 10000], 
            ['name' => 'Overhead Air', 'unit' => 'pcs', 'cost' => 100, 'stock' => 10000],
            ['name' => 'Overhead Gas', 'unit' => 'pcs', 'cost' => 100, 'stock' => 10000],
            ['name' => 'Overhead Penyusutan Mesin', 'unit' => 'pcs', 'cost' => 250, 'stock' => 10000],
            ['name' => 'Overhead Maintenance', 'unit' => 'pcs', 'cost' => 50, 'stock' => 10000],
            ['name' => 'Overhead SDM (Barista)', 'unit' => 'pcs', 'cost' => 1000, 'stock' => 10000], // Direct Labor?
        ];

        foreach ($ingredients as $ing) {
            $unitName = ucfirst($ing['unit']);
            if ($ing['unit'] === 'pcs') $unitName = 'Pieces';
            if ($ing['unit'] === 'ml') $unitName = 'Milliliter';
            
            $unit = \App\Models\Unit::firstOrCreate(
                ['abbreviation' => strtolower($ing['unit'])],
                ['name' => $unitName]
            );

            // Check if exists (including trashed)
            $existing = Ingredient::withTrashed()->where(fn($q) => $q->where('name', '=', $ing['name'], 'and'))->first();

            $ingredient = $existing;

            if ($existing) {
                if ($existing->trashed()) {
                    $existing->restore();
                }
                // Update basic info
                $existing->update([
                    'unit_id' => $unit->id,
                ]);
            } else {
                $ingredient = Ingredient::create([
                    'name' => $ing['name'],
                    'unit_id' => $unit->id,
                    'minimum_stock_alert' => 100,
                    'current_stock' => 0, // Will be updated by transaction
                    'cost_per_unit' => 0, // Will be updated by transaction
                ]);
            }

            // Create Stock In Transaction if no stock yet (or just add more? for seeding, let's assume initial stock)
            // To prevent infinite adding on re-runs, let's check if stock is 0
            if ($ingredient->current_stock == 0) {
                 \App\Models\InventoryTransaction::create([
                    'ingredient_id' => $ingredient->id,
                    'type' => 'in',
                    'quantity' => $ing['stock'],
                    'unit_cost' => $ing['cost'],
                    'total_cost' => $ing['stock'] * $ing['cost'],
                    'user_id' => $user->id,
                    'reference' => 'SEEDER_INIT',
                    'notes' => 'Initial Stock from Seeder'
                ]);

                // Update Ingredient Stock & Cost
                $ingredient->update([
                    'current_stock' => $ing['stock'],
                    'cost_per_unit' => $ing['cost']
                ]);
            }
        }
    }
}
