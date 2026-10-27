require "test_helper"

class RoutinesControllerTest < ActionDispatch::IntegrationTest
  test "library lists routines with Chinese names" do
    get root_path
    assert_response :success
    assert_select ".card__zh", text: "四十二式太极拳"
    assert_select ".card--pending .card__zh", text: /长拳/
    assert_select ".site-footer a[href='https://github.com/cloudsbird/OpenWushu']"
  end

  test "library search" do
    get root_path, params: { q: "lan que wei" }
    assert_select ".result", count: 1
  end

  test "locale switch is remembered and keeps Chinese" do
    get root_path, params: { locale: "id" }
    assert_select "html[lang=id]"
    assert_select ".lib-hero__en", text: "Rangkaian wajib"
    get routine_path(routines(:taiji))
    assert_select ".move-row__tr", text: "Sikap Pembuka"
    assert_select ".move-row__zh", text: "起势"
  end

  test "learn tab opens the selected movement" do
    get routine_path(routines(:taiji), m: 2)
    assert_response :success
    assert_select "[data-routine-player-target=list][hidden]"
    assert_select "article[data-n='2']:not([hidden])"
    assert_select "article[data-n='1'][hidden]"
    assert_select "article[data-n='2'] .pending"
    assert_select "article[data-n='1'][data-controller=figure-viewer]"
    assert_select ".carpet__label", count: 2
  end

  test "movements tab links into learn" do
    get movements_routine_path(routines(:taiji))
    assert_select "a.move-row[href=?]", routine_path(routines(:taiji), m: 2)
  end

  test "unpublished routines are not found" do
    get routine_path(routines(:changquan))
    assert_response :not_found
  end
end
