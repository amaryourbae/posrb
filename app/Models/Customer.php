<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Customer extends Model
{
    use HasFactory, HasUlids, SoftDeletes, \Laravel\Sanctum\HasApiTokens, \Illuminate\Notifications\Notifiable;

    protected $fillable = [
        'name',
        'phone',
        'email',
        'birth_date',
        'points_balance',
        'is_banned',
    ];

    protected $casts = [
        'points_balance' => 'integer',
        'is_banned' => 'boolean',
        'birth_date' => 'date',
    ];

    public function user(): HasOne
    {
        return $this->hasOne(User::class, 'member_id');
    }

    public function orders(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Order::class);
    }
}
