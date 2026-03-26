<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasUlids, SoftDeletes;

    protected $fillable = [
        'order_number',
        'user_id',
        'shift_id',
        'customer_id',
        'subtotal',
        'tax_amount',
        'discount_amount',
        'grand_total',
        'payment_method',
        'payment_status',
        'order_status',
        'order_type',
        'sales_type_id',
        'offline_id',
        'synced_at',
        'customer_name',
        'customer_phone',
        'note',
        'amount_paid',
        'change',
    ];

    protected $casts = [
        'subtotal' => 'decimal:2',
        'tax_amount' => 'decimal:2',
        'discount_amount' => 'decimal:2',
        'grand_total' => 'decimal:2',
        'synced_at' => 'datetime',
        // Optional: Enum casting if we defined Enums, using strings for now as requested
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function shift(): BelongsTo
    {
        return $this->belongsTo(Shift::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(OrderPayment::class);
    }

    public function salesType(): BelongsTo
    {
        return $this->belongsTo(SalesType::class);
    }
}
