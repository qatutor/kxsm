# (c) goodprogrammer.ru

require 'rails_helper'
require 'game_help_generator'

# Тестовый сценарий для модели игрового вопроса, в идеале весь наш функционал
# (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do
  # Задаем локальную переменную game_question, доступную во всех тестах этого
  # сценария: она будет создана на фабрике заново для каждого блока it,
  # где она вызывается.
  let(:game_question) {  FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  # Группа тестов на игровое состояние объекта вопроса
  context 'game status' do
    # Тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq(
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      )
    end

    it 'correct .answer_correct?' do
      # Именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end

    context 'task 61-2' do
      it 'validates the text method' do
        expect(game_question.text).to eq(game_question.question.text)
      end

      it 'validates the level method' do
        expect(game_question.level).to eq(game_question.question.level)
      end

    end

    # Метод correct_answer_key возвращает правильный ответ
    # let(:game_question) {  FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3) }
    # При создании game_question, указали, что правильный ответ - b
    # Проверяем что метод возвращает b
    context 'task 61-5' do
      it 'GameQuestion#correct_answer_key' do
        expect(game_question.correct_answer_key).to eq('b')
      end
    end
  end

  context 'user helpers' do
    it 'correct audience_help' do
      # Проверяем, что объект не включает эту подсказку
      expect(game_question.help_hash).not_to include(:audience_help)

      # Добавили подсказку. Этот метод реализуем в модели
      # GameQuestion
      game_question.add_audience_help

      # Ожидаем, что в хеше появилась подсказка
      expect(game_question.help_hash).to include(:audience_help)

      # Дёргаем хеш
      ah = game_question.help_hash[:audience_help]
      # Проверяем, что входят только ключи a, b, c, d
      expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
    end
  end

  context 'task 63-1' do
    it 'verifies help_hash method' do
      game_question.help_hash[:audience_help] = { 'a' => 30, 'b' => 30, 'c' => 30, 'd' => 10}
      game_question.save
      question = GameQuestion.find(game_question.id)
      expect(question.help_hash).to eq(audience_help: {'a' => 30, 'b' => 30, 'c' => 30, 'd' => 10})
    end
  end

  context 'task 63-2' do
    it 'verifies fifty_fifty method' do
      expect(game_question.help_hash).to be_empty
      game_question.add_fifty_fifty
      expect(game_question.help_hash).to include(:fifty_fifty)
      expect(game_question.help_hash[:fifty_fifty]).to eq(['a', 'b'])
    end
  end

  context 'task 63-3' do
    it 'verifies friend_call method' do
      expect(game_question.help_hash).to be_empty
      game_question.add_friend_call
      expect(game_question.help_hash).to include(:friend_call)
      expect(game_question.help_hash[:friend_call]).not_to be_empty
      friend_answer = GameHelpGenerator.friend_call(["a", "b", "c", "d"], 'b')
      expect(friend_answer).to end_with "считает, что это вариант B"
      expect(game_question.help_hash[:friend_call]).to end_with "считает, что это вариант B"
   end
  end
end
