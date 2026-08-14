class AllowSyllabusRequestsInTheQueue < ActiveRecord::Migration[8.1]
  def change
    # The queue was built for one kind of request, and its shape says so:
    # `from_state` and `to_state` are the whole payload of a lifecycle move. A
    # request to add a lesson has no state to move between — it carries a module,
    # a kind, a duration and a name in each language — so the two state columns
    # stop being required and a payload joins them.
    #
    # `null: false` with a `{}` default rather than a nullable column: a request
    # whose payload is missing and a request whose payload is empty are the same
    # broken thing, and one of them is easier to read.
    add_column :approval_requests, :payload, :json, default: {}, null: false

    change_column_null :approval_requests, :from_state, true
    change_column_null :approval_requests, :to_state, true
  end
end
