<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ModifierOption extends Model
{
    protected $fillable = [
        'modifier_id',
        'name',
        'name_prefix',
        'name_suffix',
        'icon',
        'price',
        'sort_order',
    ];

    protected $casts = [
        'price' => 'decimal:2',
    ];

    public function modifier(): BelongsTo
    {
        return $this->belongsTo(Modifier::class);
    }

    public function salePrices(): \Illuminate\Database\Eloquent\Relations\BelongsToMany
    {
        return $this->belongsToMany(SalesType::class, 'modifier_option_sale_prices')
            ->withPivot('price')
            ->withTimestamps();
    }

    public function getPriceForSalesType($salesTypeSlug)
    {
        if (empty($salesTypeSlug)) return $this->price;

        $salePrice = $this->salePrices()->where(fn($query) => $query->where('slug', '=', $salesTypeSlug, 'and'))->first();
        if ($salePrice) {
            return $salePrice->pivot->price;
        }

        return $this->price;
    }
}
