# (c) goodprogrammer.ru

# Стандартный rspec-овский помощник для rails-проекта
require 'rails_helper'

# Наш собственный класс с вспомогательными методами
require 'support/my_spec_helper'

# Тестовый сценарий для модели Игры
#
# В идеале — все методы должны быть покрыты тестами, в этом классе содержится
# ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # Пользователь для создания игр
  let(:user) { FactoryGirl.create(:user) }

  # Игра с прописанными игровыми вопросами
  let(:game_w_questions) do
    FactoryGirl.create(:game_with_questions, user: user)
  end

  let(:current_game_question) { game_w_questions.current_game_question }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # Генерим 60 вопросов с 4х запасом по полю level, чтобы проверить работу
      # RANDOM при создании игры.
      generate_questions(60)

      game = nil

      # Создaли игру, обернули в блок, на который накладываем проверки
      expect { game = Game.create_game_for_user!(user) }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15).and( change(Question, :count).by(0) )
      )

      # Проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # Проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # Тесты на основную игровую логику
  context 'game mechanics' do
    # Правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # Текущий уровень игры и статус
      level = game_w_questions.current_level

      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(current_game_question.correct_answer_key)

      # Перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)

      # Ранее текущий вопрос стал предыдущим
      expect(game_w_questions.current_game_question).not_to eq(current_game_question)

      # Игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end
  end

  context 'task 61-3' do
    it 'Game#take_money!' do
      expect(game_w_questions.status).to eq(:in_progress)
      game_w_questions.answer_current_question!(current_game_question.correct_answer_key)
      game_w_questions.take_money!
      expect(game_w_questions.status).to eq(:money)
      expect(game_w_questions.user.balance).not_to be_zero
    end
  end

  context 'task 61-4' do
    it 'game status is fail' do
      game_w_questions.answer_current_question!('c')  # :fail — игра проиграна из-за неверного вопроса
      expect(game_w_questions.status).to eq(:fail)

    end

    it 'game status is timeout' do
      game_w_questions.created_at = Time.now - (1*35*60)
      game_w_questions.time_out!                      # :timeout — игра проиграна из-за таймаута
      expect(game_w_questions.status).to eq(:timeout)
    end

    it 'game status is won' do
      game_w_questions.current_level  = 14
      game_w_questions.answer_current_question!('d')   # :won — игра выиграна (все 15 вопросов покорены)
      expect(game_w_questions.status).to eq(:won)
    end

    it 'game status is in progress' do
      game_w_questions.current_level  = 10
      game_w_questions.answer_current_question!('d')
      expect(game_w_questions.status).to eq(:in_progress)  # :in_progress — игра еще идет
    end

    it 'game status is money' do
      game_w_questions.current_level  = 8
      game_w_questions.take_money!
      expect(game_w_questions.status).to eq(:money)   # :money — игра завершена, игрок забрал деньги
    end
  end

  context 'task 61-6' do
    it 'Game#current_game_question' do
      game_w_questions.current_level = 5
      expect(game_w_questions.game_questions[5]).to eq(game_w_questions.current_game_question)
    end

    it 'Game#previous_level' do
      game_w_questions.current_level = 10
      expect(game_w_questions.previous_level).to eq(9)
    end
  end

  describe 'task 61-7' do
    context 'Ответ правильный' do
      it 'Game#answer_current_question!' do
        game_w_questions.current_level = 1
        expect(game_w_questions.answer_current_question!('d')).to be_truthy
        expect(game_w_questions.status).to eq(:in_progress)
        expect(game_w_questions.finished?).to be false
        expect(game_w_questions.current_level).to eq(2)
      end
    end

    context 'Ответ неправильный' do
      it 'Game#answer_current_question!' do
        game_w_questions.current_level = 1
        expect(game_w_questions.answer_current_question!('c')).to be_falsy
        expect(game_w_questions.status).to eq(:fail)
        expect(game_w_questions.finished?).to be true
        expect(game_w_questions.prize).to eq(0)
      end
    end

    context 'Ответ последний' do
      it 'Game#answer_current_question!' do
        game_w_questions.current_level = 14
        expect(game_w_questions.answer_current_question!('d')).to be_truthy
        expect(game_w_questions.status).to eq(:won)
        expect(game_w_questions.finished?).to be true
        expect(game_w_questions.prize).to eq(1000000)
      end
    end

    context 'Ответ по истечении времени' do
      it 'Game#answer_current_question!' do
        game_w_questions.current_level = 6
        game_w_questions.created_at = Time.now - (1*35*60)
        expect(game_w_questions.answer_current_question!('d')).to be_falsy
        expect(game_w_questions.status).to eq(:timeout)
        expect(game_w_questions.finished?).to be true
        expect(game_w_questions.prize).to eq(1000) # время вышло, получает выигрыш равный первой несгораеммой сумме
      end
    end
  end
end
