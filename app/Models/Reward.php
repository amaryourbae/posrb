<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUlids;

class Reward extends Model
{
    use HasUlids;

    protected $fillable = [
        'name',
        'description',
        'image_url',
        'point_cost',
        'type', // free_product, discount
        'product_id',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'point_cost' => 'integer',
    ];

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
