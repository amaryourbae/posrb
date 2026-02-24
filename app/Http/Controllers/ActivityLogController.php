<?php

namespace App\Http\Controllers;

use App\Models\ActivityLog;
use Illuminate\Http\Request;

use App\Traits\ApiResponse;

class ActivityLogController extends Controller
{
    use ApiResponse;
    public function index(Request $request)
    {
        $query = ActivityLog::with('user')->orderBy('created_at', 'desc');

        if ($request->has('search')) {
            $query->where('description', 'like', "%{$request->search}%")
                  ->orWhereHas('user', function ($q) use ($request) {
                      $q->where('name', 'like', "%{$request->search}%");
                  });
        }

        return $this->successResponse($query->paginate(20));
    }
}
