require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:user, is_admin:true) }
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  context 'unauthorized user' do
    it 'kicks off from #show' do
      get :show, id: game_w_questions.id
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    describe 'task 62-4' do
      it 'attempts to create a new game' do
        post :create
        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end

      it 'attempts to take money' do
        game_w_questions.update_attribute(:current_level, 2)
        put :take_money, id:game_w_questions.id
        game = assigns(:game)
        expect(game).to be_nil
        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end

      it 'attempts to answer the question' do
        put :answer, id:game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
        game = assigns(:game)
        expect(game).to be_nil
        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end
  end

  context 'authorized user' do
    before(:each) { sign_in(user) }



    it 'creates game' do
      generate_questions(15)
      post :create
      game = assigns(:game)
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    it 'shows game' do
      get :show, id: game_w_questions.id

      game = assigns(:game)
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)
      expect(response.status).to eq(200)
      expect(response).to render_template('show')
    end

    it 'answers correct' do
      put :answer, id:game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      game = assigns(:game)
      expect(game.finished?).to be_falsey
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash.empty?).to be_truthy
    end

    context 'task 62-1' do
      it 'games#show is not displayed for the different user' do
        different_game = FactoryGirl.create(:game_with_questions)
        get :show, id: different_game.id
        expect(response.status).to_not eq(200)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be
      end
    end

    context 'task 62-2' do
      it 'user requests money before game time expires' do
        game_w_questions.update_attribute(:current_level, 2)
        put :take_money, id:game_w_questions.id
        game = assigns(:game)

        expect(game.finished?).to be_truthy
        expect(game.prize).to be(200)

        user.reload
        expect(user.balance).to be(200)

        expect(response).to redirect_to(user_path(user))
        expect(flash[:warning]).to be
      end
    end

    context 'task 62-3' do
      it 'user can not start a new game if not completed the current' do
        expect(game_w_questions.finished?).to be_falsey
        expect { post :create }.to change(Game, :count).by(0)
        game = assigns(:game)
        expect(game).to be_nil
        expect(response).to redirect_to(game_path(game_w_questions))
        expect(flash[:alert]).to be
      end
    end

    context 'task 62-5' do
      it 'verifies not correct answer' do
        game_w_questions.update_attribute(:current_level, 5)
        put :answer, id:game_w_questions.id, letter: 'c'
        game = assigns(:game)
        expect(game).not_to be_nil
        expect(game.current_level).not_to be > 5
        expect(game.finished?).to be_truthy
        expect(game.prize).to be(1000)
        expect(response).to redirect_to(user_path(user))
        expect(flash[:alert]).to be
      end
    end

    it 'uses audience help' do
      # Проверяем, что у текущего вопроса нет подсказок
      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      # И подсказка не использована
      expect(game_w_questions.audience_help_used).to be_falsey

      # Пишем запрос в контроллер с нужным типом (put — не создаёт новых сущностей, но что-то меняет)
      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)

      # Проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end

    context 'task 63-4' do
      it 'verifies user can use fifty_fifty help ' do
        expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
        expect(game_w_questions.fifty_fifty_used).to be_falsey
        put :help, id: game_w_questions.id, help_type: :fifty_fifty
        game = assigns(:game)
        expect(game.finished?).to be_falsey
        expect(game.fifty_fifty_used).to be_truthy
        expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq(2)
        expect(game.current_game_question.help_hash[:fifty_fifty]).to include(game.current_game_question.correct_answer_key)
        expect(response).to redirect_to(game_path(game_w_questions))
        expect(flash{:info}).to be
      end
    end
  end
end
