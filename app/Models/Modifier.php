<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Modifier extends Model
{
    protected $fillable = [
        'name',
        'type',
        'is_required',
    ];

    protected $casts = [
        'is_required' => 'boolean',
    ];

    public function options(): HasMany
    {
        $relation = $this->hasMany(ModifierOption::class);
        $relation->getQuery()->orderBy('sort_order');
        return $relation;
    }

    public function products(): BelongsToMany
    {
        return $this->belongsToMany(Product::class, 'product_modifier')
                    ->withPivot('sort_order')
                    ->withTimestamps();
    }
}
