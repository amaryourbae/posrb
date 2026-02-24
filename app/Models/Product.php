<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Product extends Model
{
    use HasFactory, HasUlids, SoftDeletes;

    protected $fillable = [
        'category_id',
        'sku',
        'name',
        'slug',
        'description',
        'image_url',
        'price',
        'current_stock',
        'minimum_stock_alert',
        'has_recipe',
        'track_stock',
        'is_available',
        'is_favorite',
        'is_recommended',
        'is_upsell',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'current_stock' => 'decimal:2',
        'minimum_stock_alert' => 'decimal:2',
        'has_recipe' => 'boolean',
        'track_stock' => 'boolean',
        'is_available' => 'boolean',
        'is_favorite' => 'boolean',
        'is_recommended' => 'boolean',
        'is_upsell' => 'boolean',
    ];

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function ingredients(): BelongsToMany
    {
        return $this->belongsToMany(Ingredient::class, 'product_recipes')
                    ->using(ProductRecipe::class)
                    ->withPivot('quantity_needed')
                    ->withTimestamps();
    }

    public function modifiers(): BelongsToMany
    {
        return $this->belongsToMany(Modifier::class, 'product_modifier')
                    ->withPivot(['sort_order', 'condition_modifier_id', 'condition_option_id', 'allowed_options'])
                    ->withTimestamps()
                    ->orderByPivot('sort_order');
    }

    /**
     * Calculate HPP (Harga Pokok Penjualan) / COGS
     * Sum of all ingredients' cost * quantity needed
     */
    public function getHppAttribute()
    {
        return $this->ingredients->sum(function($ingredient) {
            return $ingredient->pivot->quantity_needed * $ingredient->cost_per_unit;
        });
    }

    /**
     * Calculate Max Yield (Estimasi Porsi)
     * Based on the limiting ingredient (bottleneck)
     */
    public function getMaxYieldAttribute()
    {
        // If it doesn't have a recipe (e.g. retail item), return direct stock
        if (!$this->has_recipe) {
            return (int) $this->current_stock;
        }

        // If it has a recipe but no ingredients, effectively 0 can be made
        if ($this->ingredients->isEmpty()) {
            return 0;
        }

        return $this->ingredients->min(function ($ingredient) {
            // Avoid division by zero
            if ($ingredient->pivot->quantity_needed <= 0) return 999999;
            
            return floor($ingredient->current_stock / $ingredient->pivot->quantity_needed);
        });
    }
}
