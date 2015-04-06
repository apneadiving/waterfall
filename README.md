Waterfall
=========
#### Goal

Be able to chain ruby commands, and treat them like a flow.

#### Example

Lets check with the following example, with many different outcomes, which code is not that obvious to follow:

    def submit_application
      if current_user.confirmed?
        if params[:terms_of_service]
          application = current_user.build_application
          if application.save
            render json: { ok: true }
          else 
            render_errors application.errors.full_messages
          end
        else
          render_errors 'You must accept the terms'
        end
      else
        render_errors 'You need to confirm your account first'
      end
    end
    
    def render_error(errors)
      render json: { errors: Array(errors) }, status: 422
    end

Waterfall lets you write it this way:

    def accept_group_terms
      Wf.new
        .when_falsy { current_user.confirmed? }
          .dam { 'You need to confirm your account first' }
        .when_falsy { params[:terms_of_service] }
          .dam { 'You must accept the terms' }
        .chain { @application = current_user.build_application }
        .when_falsy { @application.save }
          .dam { @application.errors.full_messages }
        .chain {  render json: { ok: true } }
        .on_dam { |errors| render json: { errors: Array(errors) }, status: 422 }
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
