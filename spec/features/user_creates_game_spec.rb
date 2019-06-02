# Как и в любом тесте, подключаем хелпер
require 'rails_helper'

# Начинаем описывать функционал для создания игры
RSpec.feature 'USER creates a game', type: :feature do
  # Готовим базу: создаём пользователя
  let(:user) { FactoryGirl.create :user }

  # А также 15 вопросов с разными уровнями сложности
  # Обратите внимание, текст вопроса и вариантов ответа
  # здесь важен — их мы потом будем проверять
  let!(:questions) do
    (0..14).to_a.map do |i|
      FactoryGirl.create(
          :question, level: i,
          text: "Когда была куликовская битва номер #{i}?",
          answer1: '1380', answer2: '1381', answer3: '1382', answer4: '1383'
      )
    end
  end

  before(:each) { login_as user}

  scenario 'successfully' do
    visit '/'
    click_link 'Новая игра'
    expect(page).to have_current_path '/games/1'
    expect(page).to have_content 'Когда была куликовская битва номер 0?'
    expect(page).to have_content '1380'
    expect(page).to have_content '1381'
    expect(page).to have_content '1382'
    expect(page).to have_content '1383'

    #save_and_open_page
  end
end