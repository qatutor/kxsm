# (c) goodprogrammer.ru

require 'rails_helper'

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
end
