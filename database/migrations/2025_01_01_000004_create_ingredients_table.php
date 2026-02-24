<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('ingredients', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->string('name');
            $table->enum('unit', ['gram', 'ml', 'pcs']);
            $table->decimal('current_stock', 10, 4)->default(0);
            $table->decimal('cost_per_unit', 10, 2)->default(0);
            $table->decimal('minimum_stock_alert', 10, 4)->default(0);
            $table->softDeletes();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ingredients');
    }
};
