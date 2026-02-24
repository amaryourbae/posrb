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
}
