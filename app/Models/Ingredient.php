<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Ingredient extends Model
{
    use HasFactory, HasUlids, SoftDeletes;

    protected $fillable = [
        'name',
        'unit',
        'current_stock',
        'cost_per_unit',
        'minimum_stock_alert',
    ];

    protected $casts = [
        'current_stock' => 'decimal:4',
        'cost_per_unit' => 'decimal:2',
        'minimum_stock_alert' => 'decimal:4',
    ];

    public function products(): BelongsToMany
    {
        return $this->belongsToMany(Product::class, 'product_recipes')
                    ->using(ProductRecipe::class)
                    ->withPivot('quantity_needed')
                    ->withTimestamps();
    }
}
