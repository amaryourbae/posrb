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
        Schema::create('product_modifier', function (Blueprint $table) {
            $table->id();
            $table->timestamps();
            $table->unsignedBigInteger('modifier_id');
            $table->foreign('modifier_id')->references('id')->on('modifiers')->onDelete('cascade');
            $table->char('product_id', 26);
            $table->foreign('product_id')->references('id')->on('products')->onDelete('cascade');
            $table->integer('sort_order')->default(0);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('product_modifier');
    }
};
