import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  final String activeUserId;
  const TasksScreen({Key? key, required this.activeUserId}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserTask> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await ApiService.fetchUserTasks(widget.activeUserId);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tasks: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('కార్యములు (Tasks)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE5A93C),
          labelColor: const Color(0xFFE5A93C),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '🔴 New'),
            Tab(text: '🟡 In Progress'),
            Tab(text: '🟢 Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A93C)))
          : RefreshIndicator(
              onRefresh: _loadTasks,
              color: const Color(0xFFE5A93C),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList(_tasks.where((t) => t.status == 'NEW').toList()),
                  _buildTaskList(_tasks.where((t) => t.status == 'IN_PROGRESS').toList()),
                  _buildTaskList(_tasks.where((t) => t.status == 'COMPLETED').toList()),
                ],
              ),
            ),
    );
  }

  Widget _buildTaskList(List<UserTask> taskList) {
    if (taskList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white24, size: 64),
            SizedBox(height: 12),
            Text('టాస్క్‌లు లేవు (No tasks in this category)', style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: taskList.length,
      itemBuilder: (context, index) {
        final task = taskList[index];
        final isCompleted = task.status == 'COMPLETED';

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(color: Color(0xFFE5A93C), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green.withOpacity(0.2) : const Color(0xFFE5A93C).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted ? Colors.greenAccent : const Color(0xFFE5A93C),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isCompleted ? '✓ Completed' : task.dueDate,
                        style: TextStyle(
                          color: isCompleted ? Colors.greenAccent : const Color(0xFFE5A93C),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'పురోగతి: ${task.completedItems} / ${task.totalItems} పదాలు',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: task.progressPercent,
                            backgroundColor: const Color(0xFF0F172A),
                            color: isCompleted ? Colors.greenAccent : const Color(0xFFE5A93C),
                            minHeight: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailScreen(
                              taskId: task.id,
                              activeUserId: widget.activeUserId,
                              onTaskCompleted: _loadTasks,
                            ),
                          ),
                        ).then((_) => _loadTasks());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted ? const Color(0xFF334155) : const Color(0xFFE5A93C),
                        foregroundColor: isCompleted ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text(
                        isCompleted ? 'సమీక్ష (REVIEW)' : 'START (ప్రారంభించు)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
