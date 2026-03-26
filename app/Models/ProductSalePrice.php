<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\Pivot;
use Illuminate\Database\Eloquent\Concerns\HasUlids;

class ProductSalePrice extends Pivot
{
    use HasUlids;

    protected $table = 'product_sale_prices';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'product_id',
        'sales_type_id',
        'price',
    ];

    protected $casts = [
        'price' => 'decimal:2',
    ];
}
