
require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let (:user) { FactoryGirl.build_stubbed(:user, name: 'Jhon', balance: 5000) }
  let(:game) { FactoryGirl.build_stubbed( :game, id: 15, created_at: Time.parse('2016.10.09, 13:00'), current_level: 10, prize: 1000 ) }

  before(:each) do
    allow(game).to receive(:status).and_return(:in_progress)
    allow(view).to receive(:user_signed_in?) { true }
    allow(view).to receive(:current_user) { user }
    assign(:user, user)
    render
  end

  # пользователь видит свое имя
  it 'user name is displayed on show page' do
    expect(rendered).to match 'Jhon'
  end

  # текущий пользователь (и только он) видит кнопку для смены пароля
  it 'change psw btn is displayed for current user' do
    expect(rendered).to match 'Сменить имя и пароль'
  end

  #что на странице отрисовываются фрагменты с игрой
  it 'page show displays game info' do
    render partial: 'users/game', object: game

    expect(rendered).to match 'в процессе'
    expect(rendered).to match '10'
    expect(rendered).to match '1 000 ₽'
    expect(rendered).to match '50/50'
    expect(rendered).to match 'fa-phone'
    expect(rendered).to match 'fa-users'
  end

end