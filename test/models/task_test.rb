require "test_helper"

class TaskTest < ActiveSupport::TestCase
  setup do
    @parent = tasks(:parent_task)
    @subtask_one = tasks(:subtask_one)
    @subtask_two = tasks(:subtask_two)
    @root_task = tasks(:two)
  end

  # === Associations ===

  test "parent task has many subtasks" do
    assert_includes @parent.subtasks, @subtask_one
    assert_includes @parent.subtasks, @subtask_two
  end

  test "subtask belongs to parent" do
    assert_equal @parent, @subtask_one.parent
  end

  test "root task has no parent" do
    assert_nil @root_task.parent
  end

  # === Validations ===

  test "cannot create subtask under a subtask (1-level limit)" do
    grandchild = Task.new(
      name: "Grandchild",
      project: @subtask_one.project,
      created_by: @subtask_one.created_by,
      parent: @subtask_one,
    )
    assert_not grandchild.valid?
    assert grandchild.errors[:parent_id].any?
  end

  test "subtask must belong to same project as parent" do
    other_project = projects(:one)
    subtask = Task.new(
      name: "Wrong Project Subtask",
      project: other_project,
      created_by: @parent.created_by,
      parent: @parent,
    )
    assert_not subtask.valid?
    assert subtask.errors[:project_id].any?
  end

  # === Scopes ===

  test "root_tasks scope excludes subtasks" do
    root_tasks = Task.root_tasks
    assert_includes root_tasks, @parent
    assert_includes root_tasks, @root_task
    assert_not_includes root_tasks, @subtask_one
    assert_not_includes root_tasks, @subtask_two
  end

  # === complete! cascade ===

  test "complete! cascades to uncompleted subtasks" do
    assert_not @subtask_one.completed?
    @parent.complete!
    @subtask_one.reload
    assert @subtask_one.completed?
  end

  test "complete! on parent marks parent as completed" do
    @parent.complete!
    assert @parent.reload.completed?
  end

  test "complete! on subtask does not affect parent" do
    @subtask_one.complete!
    assert_not @parent.reload.completed?
  end

  # === uncomplete! ===

  test "uncomplete! on parent does not change subtask state" do
    @parent.complete!
    @parent.uncomplete!
    # subtask_one was cascaded to completed, should stay completed
    assert @subtask_one.reload.completed?
  end

  # === dependent: :destroy ===

  test "destroying parent destroys subtasks" do
    subtask_ids = @parent.subtask_ids
    assert subtask_ids.any?
    @parent.destroy
    subtask_ids.each do |id|
      assert_nil Task.find_by(id: id)
    end
  end

  # === Helper methods ===

  test "subtask? returns true for subtask" do
    assert @subtask_one.subtask?
  end

  test "subtask? returns false for root task" do
    assert_not @root_task.subtask?
  end

  test "parent? returns true for task with subtasks" do
    assert @parent.parent?
  end

  test "parent? returns false for task without subtasks" do
    assert_not @root_task.parent?
  end
end
