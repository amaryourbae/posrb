<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ResetTransactionData extends Command
{
    protected $signature = 'data:reset-transactions
                            {--force : Skip confirmation prompt}';

    protected $description = 'Truncate all transaction & shift related tables while keeping master data (products, categories, users, etc.)';

    public function handle(): int
    {
        $tables = [
            // Child tables first (foreign key order)
            'order_items',
            'order_payments',
            'cash_movements',
            'activity_logs',
            'inventory_transactions',
            // Parent tables
            'orders',
            'shifts',
        ];

        $this->warn('⚠️  The following tables will be TRUNCATED (all data deleted):');
        $this->table(['Table'], array_map(fn ($t) => [$t], $tables));

        $this->info('Tables that will NOT be affected: users, products, categories, customers, ingredients, settings, modifiers, etc.');

        if (! $this->option('force') && ! $this->confirm('Are you sure you want to continue? This action is IRREVERSIBLE.')) {
            $this->info('Cancelled.');
            return Command::SUCCESS;
        }

        // Disable foreign key checks to allow truncation in any order
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');

        foreach ($tables as $table) {
            if (Schema::hasTable($table)) {
                DB::table($table)->truncate();
                $this->line("  ✅ Truncated: <info>{$table}</info>");
            } else {
                $this->line("  ⏭️  Skipped (not found): <comment>{$table}</comment>");
            }
        }

        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        $this->newLine();
        $this->info('✅ All transaction & shift data has been reset successfully!');

        return Command::SUCCESS;
    }
}
