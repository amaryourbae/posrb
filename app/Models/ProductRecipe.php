<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\Pivot;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\SoftDeletes;

class ProductRecipe extends Pivot
{
    use HasUlids, SoftDeletes;

    protected $table = 'product_recipes';

    public $incrementing = true;

    protected $fillable = [
        'product_id',
        'ingredient_id',
        'quantity_needed',
    ];

    protected $casts = [
        'quantity_needed' => 'decimal:4',
    ];
}
