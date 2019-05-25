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
  end


end
