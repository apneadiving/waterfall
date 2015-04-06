Waterfall
=========
#### Goal

Be able to chain ruby commands, and treat them like a flow.

#### Example

Lets check a rather complex example, with many different outcomes, so the code not that obvious to follow:

    def accept_group_terms
      if current_entity.user? && notification.group_terms?
        if params[:terms_of_service][:checked]
          user_group = notification.entity.user_groups.with_user(current_entity).first
          if user_group
            user_group.terms_accepted_at = Time.now
            user_group.save
            notification.mark_as_read_by(current_entity).save!
            render_notif
          else
            render_error 'You are not allowed to answer this form'
          end
        else
          render_error 'You must accept the terms'
        end
      else
        render_error 'You cannot answer this form'
      end
    end
    
    def render_error(error)
      render json: { errors: [ error ] }, status: 422
    end

Waterfall lets you write it this way:

    def accept_group_terms
      Wf.new
        .when_falsy { current_entity.user? && notification.group_terms? }
          .dam { 'You cannot answer this form' }
        .when_falsy { params[:terms_of_service][:checked] }
          .dam { 'You must accept the terms' }
        .when_falsy { @user_group = notification.entity.user_groups.with_user(current_entity).first }
          .dam { 'You are not allowed to answer this form' }
        .chain {
          @user_group.terms_accepted_at = Time.now
          @user_group.save
          notification.mark_as_read_by(current_entity).save!
          render_notif      
        }
        .on_dam { |err| render json: { errors: [err] }, status: 422 }
    end

Once the flow faces a `dam`, all following instructions are skipped, until an `on_dam` is found.

Moreover, if you move this code to an object, you'll have the ability to chain it.
See other examples:
- https://gist.github.com/apneadiving/b1e9d30f08411e24eae6
- https://gist.github.com/apneadiving/f1de3517a727e7596564


#### Rationale
Coding is all about writing a flow of commands.

Generally you basically go on, unless something wrong happens. Whenever this happens you have to halt the flow and send feedback to the user.

Basically:

    if user.save
      flash[:success] = 'User updated'
      redirect_to user  
    else
      flash[:error] = "User not saved"  
      render :show 
    end
  
  
When conditions stack up, readability decreases. One way to solve it is to create abstractions (service objects or the like). Some gems suggest a nice approach like [light service](https://github.com/adomokos/light-service) and [interactor](https://github.com/collectiveidea/interactor).

I like these approaches, but I dont like to have to write a class each time I need to chain services.

My take on this was to create `waterfall`.

Thanks
=========
Huge thanks to [laxrph10](https://github.com/laxrph10) for the help during infinite naming brainstorming.
