# ==================ИНТЕРФЕЙС=======================
ui <- fluidPage(
  theme = shinytheme("slate"),
  
  titlePanel("Результаты рекомендации и предсказания цены"),
  
  sidebarLayout(
    sidebarPanel(
      column(6, 
             selectInput(inputId = "district", label = "Введите название района",
                         selected = as.factor(levels(sort(data_final$district)[1])),
                         choices = sort(data_final$district)),
             
             selectInput(inputId = "subway", label = "Выберите ближайшее метро", 
                         selected = as.factor(levels(sort(data_final$remont)[1])),
                         choices = sort(data_final$subway_TRUE)),
             
             numericInput("min_subway", label = ("Укажите сколько минут до метро пешком"), 
                          min = 1, max = 40, step = 1, value = 1),
             
             numericInput(inputId = "year", label = "Введите год постройки",  
                          min = 1746, max = 2022, value = 1965, step = 1),
             
             selectInput(inputId = "house_type", label = "Выберите тип дома", 
                         selected = as.factor(levels(sort(data_final$housetype)[1])),
                         choices = sort(data_final$housetype)),
             
             sliderInput(inputId = "floor", label = "Выберите этаж", 
                         min = 1, max = 40, value = 1, step = 1),
             
             selectInput(inputId = "rooms", label = "Введите количество комнат",
                         selected = as.factor(levels(sort(data_final$rooms)[1])),
                         choices = sort(data_final$rooms))),
      column(5,
             numericInput("num_square", label = ("Укажите общую площадь"), min = 1, value = 1, step = 1),
             
             numericInput("num_kitsquare", label = ("Укажите площадь кухни"), min = 1, value = 1, step = 1),
             
             numericInput("num_livsquare", label = ("Укажите жилую площадь"), min = 1, value = 1, step = 1),
             
             selectInput(inputId = "remont", label = "Выберите тип ремонта",
                         selected = as.factor(levels(sort(data_final$remont)[1])), 
                         choices = sort(data_final$remont)),
             
             radioButtons("balcony", "Наличие балкона",
                          selected = 1,
                          c("Есть" = 1,
                            "Нет" = 0)),
             
             radioButtons("elevator", "Наличие лифта",
                          selected = 1,
                          c("Есть" = 1,
                            "Нет" = 0)),
             
             selectInput(inputId = "toilet_type", label = "Выберите тип санузла", 
                         selected = as.factor(levels(sort(data_final$type_toilet)[1])),
                         choices = c("раздельный"= 1, 
                                     "совмещенный"= 0)),
             
             numericInput(inputId = "toilet_quantity", label = "Введите количество санузлов", 
                          min = 1, value = 1, step = 1)),
      
      actionButton("button", "Предсказать цену"),
      width = 5 # ширина инпута
    ),
    
    mainPanel(
      tabsetPanel(type = "tabs",
                  tabPanel("Похожие квартиры", withLoader(leafletOutput("mymap", 
                                                                        width = "115%", height = 600), 
                                                          type="html", loader="loader1")),
                  
                  tabPanel("Рекомендованная цена", withLoader(htmlOutput("prediction"), 
                                                              type="html", loader="loader1"))
      ),
      width = 6 # ширина аутпута
      
    )
  )
)

server <- function(input, output) {
  data_user <- eventReactive(input$button, {  
    data_user = data.frame(id = 9999,
                           square = as.numeric(input$num_square),
                           rooms = as.character(input$rooms),
                           kitchen_square = as.numeric(input$num_kitsquare),
                           living_square = as.numeric(input$num_livsquare),
                           year = as.numeric(input$year),
                           toilet_quantity = as.numeric(input$toilet_quantity),
                           type_toilet = as.numeric(input$toilet_type),
                           if_lift = as.numeric(input$elevator),
                           if_balcony = as.numeric(input$balcony),
                           housetype = as.character(input$house_type),
                           remont = as.character(input$remont),
                           subway_dist_peshkom_TRUE = as.numeric(input$min_subway),
                           district = as.character(input$district),
                           floor = as.numeric(input$floor),
                           subway_TRUE = as.character(input$subway))
    data_user
    
  })
  
  # ==================РЕК.СИСТЕМА=======================
  recommend = reactive({
    data_final = read_excel("D:/HSE/3 курс/дата саенс/data_final.xlsx")
    data1 = data_final %>% select(id,
                                  square,
                                  rooms,
                                  district,
                                  kitchen_square,
                                  living_square,
                                  floor,
                                  year,
                                  toilet_quantity,
                                  type_toilet,
                                  if_balcony,
                                  if_lift,
                                  housetype,
                                  remont,
                                  subway_TRUE,
                                  subway_dist_peshkom_TRUE)
    
    
    data_user = data_user() #параметры, введенные пользователем
    data_cont = rbind(data1, data_user)
    
    data_cont$square_cat = paste(as.character(round(data_cont$square/10,0)),"square")
    data_cont$kitchen_square_cat = paste(as.character(round(data_cont$kitchen_square/10,0)),"kitchen_square")
    data_cont$living_square_cat = paste(as.character(round(data_cont$living_square/10,0)),"living_square")
    data_cont$subway_dist_cat = paste(as.character(round(data_cont$subway_dist_peshkom_TRUE/5,0)),"subway")
    data_cont$floor = paste(as.character(data_cont$floor),"floor")
    data_cont$year = as.character(data_cont$year)
    data_cont$toilet_quantity = paste(as.character(data_cont$toilet_quantity),"toilet")
    data_cont$type_toilet = paste(as.character(data_cont$type_toilet),"type_toilet")
    data_cont$if_balcony = paste(as.character(data_cont$if_balcony),"balcony")
    data_cont$if_lift = paste(as.character(data_cont$if_lift),"lift")
    
    
    #приводим к широкому формату
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=rooms,values_from=exist,values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=floor,values_from=exist,values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=year,values_from=exist,values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=toilet_quantity,values_from=exist,names_repair = "minimal",values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=type_toilet,values_from=exist,values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=if_balcony,values_from=exist,names_repair = "minimal",values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=if_lift,values_from=exist,names_repair = "minimal",values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=district,values_from=exist,values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=remont,values_from=exist,values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=housetype,values_from=exist,values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=subway_TRUE,values_from=exist,values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=square_cat,values_from=exist,values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=kitchen_square_cat,values_from=exist,values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=living_square_cat,values_from=exist,values_fill = 0)
    data_cont$exist = 1
    data_cont = data_cont %>% pivot_wider(names_from=subway_dist_cat,values_from=exist,values_fill = 0)
    
    
    id=data_cont$id
    #удаляем ненужные переменные
    data_cont = data_cont %>% select(-c(id, square, kitchen_square, living_square, subway_dist_peshkom_TRUE))
    rownames(data_cont)=id
    a=as.matrix(data_cont)
    t=t(a)
    sim = coop::cosine(t)
    diag(sim) = 0
    
    sim_1 = sim
    sim_1["9999",]
    simCut = sim_1[,"9999"]
    mostSimilar = head(sort(simCut, decreasing = T), n = 5)
    a = which(simCut %in% mostSimilar, arr.ind = TRUE, useNames = T)
    a = a[1:5]
    index = arrayInd(a, .dim = dim(sim))
    result = rownames(sim)[index[,1]]
    recommend = data_final %>% filter(row.names(data_final) %in% result)
    recommend$shirota = as.numeric(recommend$shirota)
    recommend$dolgota = as.numeric(recommend$dolgota)
    recommend
  })
  
  #похожие квартиры
  output$mymap = renderLeaflet({
    vector1 = c(1, 0)
    vector2 = c("есть", "нет")
    
    recommend = recommend()
    M = leaflet(recommend) %>% setView(lng = 30.3141, lat = 59.9386, zoom = 10)
    M %>% addTiles() %>%
      addMarkers(~dolgota, ~shirota, popup = paste("<br>Адрес:", recommend$addr,
                                                   "<br>Район:", recommend$district,
                                                   "<br>Цена:", paste0(formatC(as.numeric(recommend$price), format="f", digits=0, big.mark="'"), " ₽"),
                                                   "<br>Кол-во комнат:", recommend$rooms,
                                                   "<br>Площадь (кв.м):", recommend$square,
                                                   "<br>Жилая площадь (кв.м):", recommend$living_square,
                                                   "<br>Площадь кухни (кв.м):", recommend$kitchen_square,
                                                   "<br>Этаж:", recommend$floor,
                                                   "<br>Год постройки:", recommend$year,
                                                   "<br>Тип дома:", recommend$housetype,
                                                   "<br>Балкон:", recommend$if_balcony,
                                                   "<br>Наличие лифта:", recommend$if_lift,
                                                   "<br>Кол-во санузлов:", recommend$toilet_quantity,
                                                   "<br>Тип туалета:", recommend$type_toilet,
                                                   "<br>Ремонт:", recommend$remont,
                                                   "<br>Станция метро:", recommend$subway_TRUE,
                                                   "<br>Пешком до метро (мин):", recommend$subway_dist_peshkom_TRUE),
                 label = paste0(formatC(as.numeric(recommend$price), format="f", digits=0, big.mark="'"), " ₽"))
  })
  
  # ==================ПРЕДСКАЗАТЕЛЬНАЯ МОДЕЛЬ=======================
  output$prediction = renderUI({
    # загружаем RDA
    load("D:/HSE/3 курс/дата саенс/model1.Rda")
    load("D:/HSE/3 курс/дата саенс/model2.Rda")
    load("D:/HSE/3 курс/дата саенс/model3.Rda")
    load("D:/HSE/3 курс/дата саенс/model4.Rda")
    load("D:/HSE/3 курс/дата саенс/model5.Rda")
    load("D:/HSE/3 курс/дата саенс/model6.Rda")
    load("D:/HSE/3 курс/дата саенс/lamb1.Rda")
    load("D:/HSE/3 курс/дата саенс/lamb2.Rda")
    
    data_user = data_user()
    
    data = data_user
    
    data$rooms = case_when(data_user$rooms =="1"~1, data_user$rooms =="2"~2, data_user$rooms =="3"~3, data_user$rooms == "4"~4, data_user$rooms =="5"~5, data_user$rooms == "Апартаменты-студия"~6, data_user$rooms =="Квартира свободной планировки"~7, data_user$rooms == "Многокомнатная квартира"~8, data_user$rooms == "Многокомнатные апартаменты"~9, data_user$rooms == "Студия"~10)
    data$district = case_when(data_user$district == "Адмиралтейский"~1, data_user$district == "Василеостровский"~2, data_user$district == "Выборгский"~3, data_user$district == "Калининский"~4, data_user$district == "Кировский"~5, data_user$district == "Колпинский"~6, data_user$district == "Красногвардейский"~7, data_user$district == "Красносельский"~8, data_user$district == "Кронштадтский"~9, data_user$district == "Курортный"~10, data_user$district == "Московский"~11, data_user$district == "Невский"~12, data_user$district == "Петроградский"~13, data_user$district == "Петродворцовый"~14, data_user$district == "Приморский"~15, data_user$district == "Пушкинский"~16, data_user$district == "Фрунзенский"~17, data_user$district == "Центральный"~18)
    data$housetype = case_when(data_user$housetype == "Блочный"~1, data_user$housetype == "Кирпичный"~2, data_user$housetype == "Монолитный"~3, data_user$housetype == "Панельный"~4, data_user$housetype == "Сталинский"~5)
    data$remont = case_when(data_user$remont == "Без ремонта"~1, data_user$remont == "Дизайнерский"~2, data_user$remont == "Евроремонт"~3, data_user$remont == "Косметический"~4)
    data$subway_TRUE = case_when(data_user$subway_TRUE == "Автово"~1, data_user$subway_TRUE == "Адмиралтейская"~2, data_user$subway_TRUE == "Академическая"~3, data_user$subway_TRUE == "Балтийская"~4, data_user$subway_TRUE == "Беговая"~5, data_user$subway_TRUE == "Бухарестская"~6, data_user$subway_TRUE == "Василеостровская"~7, data_user$subway_TRUE == "Владимирская"~8, data_user$subway_TRUE == "Волковская"~9, data_user$subway_TRUE == "Выборгская"~10, data_user$subway_TRUE == "Горьковская"~11, data_user$subway_TRUE == "Гостиный двор"~12, data_user$subway_TRUE == "Гражданский проспект"~13, data_user$subway_TRUE == "Девяткино"~14, data_user$subway_TRUE == "Достоевская"~15, data_user$subway_TRUE == "Дунайская"~16, data_user$subway_TRUE == "Елизаровская"~17, data_user$subway_TRUE == "Звездная"~18, data_user$subway_TRUE == "Звенигородская"~19, data_user$subway_TRUE == "Зенит"~20, data_user$subway_TRUE == "Кировский завод"~21, data_user$subway_TRUE == "Комендантский проспект"~22, data_user$subway_TRUE == "Крестовский остров"~23, data_user$subway_TRUE == "Купчино"~24, data_user$subway_TRUE == "Ладожская"~25, data_user$subway_TRUE == "Ленинский проспект"~26, data_user$subway_TRUE == "Лесная"~27, data_user$subway_TRUE == "Лиговский проспект"~28, data_user$subway_TRUE == "Ломоносовская"~29, data_user$subway_TRUE == "Маяковская"~30, data_user$subway_TRUE == "Международная"~31, data_user$subway_TRUE == "Московская"~32, data_user$subway_TRUE == "Московские ворота"~33, data_user$subway_TRUE == "Нарвская"~34, data_user$subway_TRUE == "Невский проспект"~35, data_user$subway_TRUE == "Новочеркасская"~36, data_user$subway_TRUE == "Обводный канал"~37, data_user$subway_TRUE == "Обухово"~38, data_user$subway_TRUE == "Озерки"~39, data_user$subway_TRUE == "Парк Победы"~40, data_user$subway_TRUE == "Парнас"~41, data_user$subway_TRUE == "Петроградская"~42, data_user$subway_TRUE == "Пионерская"~43, data_user$subway_TRUE == "Площадь Александра Невского"~44, data_user$subway_TRUE == "Площадь Восстания"~45, data_user$subway_TRUE == "Площадь Ленина"~46, data_user$subway_TRUE == "Площадь Мужества"~47, data_user$subway_TRUE == "Политехническая"~48, data_user$subway_TRUE == "Приморская"~49, data_user$subway_TRUE == "Пролетарская"~50, data_user$subway_TRUE == "Проспект Большевиков"~51, data_user$subway_TRUE == "Проспект Ветеранов"~52, data_user$subway_TRUE == "Проспект Просвещения"~53, data_user$subway_TRUE == "Проспект Славы"~54, data_user$subway_TRUE == "Пушкинская"~55, data_user$subway_TRUE == "Рыбацкое"~56, data_user$subway_TRUE == "Садовая"~57, data_user$subway_TRUE == "Сенная площадь"~58, data_user$subway_TRUE == "Спасская"~59, data_user$subway_TRUE == "Спортивная"~60, data_user$subway_TRUE == "Старая Деревня"~61, data_user$subway_TRUE == "Технологический институт"~62, data_user$subway_TRUE == "Удельная"~63, data_user$subway_TRUE == "Улица Дыбенко"~64, data_user$subway_TRUE == "Фрунзенская"~65, data_user$subway_TRUE == "Черная речка"~66, data_user$subway_TRUE == "Чернышевская"~67, data_user$subway_TRUE == "Чкаловская"~68, data_user$subway_TRUE == "Шушары"~69, data_user$subway_TRUE == "Электросила"~70)
    
    
    data_user$rooms = data_user$rooms %>% as.factor()
    levels(data_user$rooms) = c("1", "2", "3", "4", "5", "Апартаменты-студия", "Квартира свободной планировки", "Многокомнатная квартира", "Многокомнатные апартаменты", "Студия")
    
    data_user$district = as.factor(data_user$district)
    levels(data_user$district) = c("Адмиралтейский", "Василеостровский", "Выборгский", "Калининский", "Кировский", "Колпинский", "Красногвардейский", "Красносельский", "Кронштадтский", "Курортный", "Московский", "Невский", "Петроградский", "Петродворцовый", "Приморский", "Пушкинский", "Фрунзенский", "Центральный")
    
    data_user$housetype = as.factor(data_user$housetype)
    levels(data_user$housetype) = c("Блочный", "Кирпичный","Монолитный","Панельный","Сталинский")
    
    data_user$remont = data_user$remont %>% as.factor()
    levels(data_user$remont) = c("Без ремонта", "Дизайнерский", "Евроремонт", "Косметический")
    
    data_user$subway_TRUE = data_user$subway_TRUE %>% as.factor()
    levels(data_user$subway_TRUE) = c("Автово", "Адмиралтейская", "Академическая", "Балтийская", "Беговая", "Бухарестская", "Василеостровская", "Владимирская", "Волковская", "Выборгская", "Горьковская", "Гостиный двор", "Гражданский проспект", "Девяткино", "Достоевская", "Дунайская", "Елизаровская", "Звездная", "Звенигородская", "Зенит", "Кировский завод", "Комендантский проспект", "Крестовский остров", "Купчино", "Ладожская", "Ленинский проспект", "Лесная", "Лиговский проспект", "Ломоносовская", "Маяковская", "Международная", "Московская", "Московские ворота", "Нарвская", "Невский проспект", "Новочеркасская", "Обводный канал", "Обухово", "Озерки", "Парк Победы", "Парнас", "Петроградская", "Пионерская", "Площадь Александра Невского", "Площадь Восстания", "Площадь Ленина", "Площадь Мужества", "Политехническая", "Приморская", "Пролетарская", "Проспект Большевиков", "Проспект Ветеранов", "Проспект Просвещения", "Проспект Славы", "Пушкинская", "Рыбацкое", "Садовая", "Сенная площадь", "Спасская", "Спортивная", "Старая Деревня", "Технологический институт", "Удельная", "Улица Дыбенко", "Фрунзенская", "Черная речка", "Чернышевская", "Чкаловская", "Шушары", "Электросила")
    
    
    matr_data_user = data.matrix(data[,2:16])
    
    pred1 = predict(model1_wf, data_user)
    pred2 = predict(model2_wf, data_user)
    pred3 = predict(ridge_model, s = best_lambda, newx = matr_data_user)
    pred4 = predict(lasso_model, s = best_lambda2, newx = matr_data_user)
    pred5 = predict(rf, data_user)
    # pred6 = predict(xgb_final, data_user) # почему-то не работает
    
    prediction = 0.22*pred1+0.22*pred2+0.22*pred3+0.22*pred4+0.12*pred5
    HTML(paste("Рекомендованная цена продажи Вашей квартиры составляет примерно: ", "<br>", 
               "<font size = 30, color = 'white'>", formatC(round(0.98*as.numeric(prediction),-4), format="f", digits=0, big.mark="'"),"–",formatC(round(1.02*as.numeric(prediction),-4), format="f", digits=0, big.mark="'"),"₽", "</font>"))
  })
  
}

shinyApp(ui = ui, server = server)
Обучение моделей
library(tidymodels)
library(readr)
library(readxl)
library(ggplot2)
library(GGally)
library(psych)
library(mlbench)
library(caret)
library(caretEnsemble)
library(lmtest)
library(xgboost)
library(glmnet)
library(randomForest)

# ========================ЗАГРУЗКА=============================
df = read_xlsx("D:/HSE/3 курс/дата саенс/data_final.xlsx", col_names = T)

df$shirota = df$shirota %>% as.numeric()
df$dolgota = df$dolgota %>% as.numeric()
df$shirota = df$shirota %>% as.numeric()
df$floor = df$floor %>% as.numeric()
df$if_balcony = df$if_balcony %>% as.numeric()
df$if_lift = df$if_lift %>% as.numeric()
df$type_toilet = df$type_toilet %>% as.numeric()


df$rooms = df$rooms %>% as.factor()
df$district = df$district %>% as.factor()
df$housetype = df$housetype %>% as.factor()
df$remont = df$remont %>% as.factor()
df$subway_TRUE = df$subway_TRUE %>% as.factor()

# =====================УДАЛЕНИЕ ВЫБРОСОВ========================
tab = psych::describe(select(df, -c(id, addr, shirota, dolgota, opisanie, district, floor, subway_TRUE, rooms, type_toilet,if_lift, if_balcony, housetype, remont)), IQR = T, skew = F, quant=c(.25,.75)) %>% as.data.frame()
tab = tab %>% select(-c(n, vars, se))

litter_price = 1.5*tab[["IQR"]][1] + tab[["Q0.75"]][1] # ака 1.5*IQR+Q0.75
litter_dist = 1.5*tab[["IQR"]][7] + tab[["Q0.75"]][7]
# несмотря на значение litter_dist, удалим наблюдения больше 60 минут, т.к. в ходе тестирования предсказания была выявлена излишняя чувствительность предсказания к удаленности от метро пешком
df = df %>% filter(price<=litter_price) %>% filter(subway_dist_peshkom_TRUE<=60)
df = df %>% select(-c(id, opisanie, addr, shirota, dolgota))

# ======================ОБУЧЕНИЕ МОДЕЛЕЙ========================
set.seed(523)
split = initial_split(df, prop = 0.8)
train_df = training(split)
test_df = testing(split)

fmla = as.formula("price ~ square+rooms+district+kitchen_square+living_square+floor+year+toilet_quantity+type_toilet+if_lift+if_balcony+housetype+remont+subway_TRUE+subway_dist_peshkom_TRUE")

# Модель 1
model1 = decision_tree(mode = 'regression') %>% 
  set_engine("rpart")

model1_wf = workflow() %>%
  add_formula(fmla) %>%
  add_model(model1) %>%
  fit(train_df)

set.seed(523)
folds = rsample::vfold_cv(train_df, v = 10, repeats = 5)
train_tune = tune_grid(model1_wf, resamples = folds)
train_best = train_tune %>% select_best("rmse")
final_model1 = finalize_model(model1, train_best)

model1_wf = workflow() %>%
  add_formula(fmla) %>%
  add_model(final_model1) %>%
  fit(train_df)

pred_train = predict(model1_wf, train_df) # Примечение: начиная со следующей модели, строки с расчетом RMSE не приводятся для уменьшения длины кода, хотя в действительности такие вычисления производились
pred_rmse11 = mean((pred_train$.pred - train_df$price)^2)^0.5
pred_test = predict(model1_wf, test_df)
pred_rmse12 = mean((pred_test$.pred - test_df$price)^2)^0.5

# Модель 2
fmla2 = as.formula("price ~ square+rooms+kitchen_square+living_square+year+toilet_quantity+type_toilet+if_lift+if_balcony")

model2 = decision_tree(mode = 'regression') %>% 
  set_engine("rpart")

model2_wf = workflow() %>%
  add_formula(fmla2) %>%
  add_model(model2) %>%
  fit(train_df)

set.seed(523)
folds = rsample::vfold_cv(train_df, v = 10, repeats = 5)
train_tune2 = tune_grid(model2_wf, resamples = folds)
train_best2 = train_tune2 %>% select_best("rmse")
final_model2 = finalize_model(model2, train_best2)

model2_wf = workflow() %>%
  add_formula(fmla10) %>%
  add_model(final_model2) %>%
  fit(train_df)

# Модель 3
train_df_matr = data.matrix(train_df[,2:16])

set.seed(523)
ridge_model = cv.glmnet(train_df_matr, train_df[[1]], alpha = 0, nfolds = 20, relax = T)
best_lambda = ridge_model$lambda.min
ridge_model = glmnet(train_df_matr, train_df[[1]], alpha = 0, lambda = best_lambda)

pred3_train = predict(ridge_model, s = best_lambda, newx = data.matrix(train_df[,2:16]))
pred_rmse31 = mean((pred3_train - train_df$price)^2)^0.5
pred3_test = predict(ridge_model, s = best_lambda, newx = data.matrix(test_df[,2:16]))
pred_rmse32 = mean((pred3_test - test_df$price)^2)^0.5

# Модель 4
set.seed(523)
lasso_model = cv.glmnet(train_df_matr, train_df[[1]], alpha = 1, nfolds = 20, relax = T)
best_lambda2 = lasso_model$lambda.min
lasso_model = glmnet(train_df_matr, train_df[[1]], alpha = 1, lambda = best_lambda2)

# Модель 5
fmla3 = as.formula("price ~ square+rooms+kitchen_square+living_square+year+toilet_quantity+type_toilet+if_lift+if_balcony")
set.seed(523)
rf = randomForest(formula = fmla3, data = train_df,
                  mtry = 5, ntrees = 500, importance = T)

# Модель 6
xgb = boost_tree(trees = 500, tree_depth = tune()) %>%
  set_mode("regression") %>% 
  set_engine("xgboost")

set.seed(523)
folds2 = rsample::vfold_cv(train_df, v = 4, repeats = 4)
tune_grid_boost = grid_regular(parameters(xgb), levels=c(tree_depth = 3), filter = tree_depth <= 10)

tune_res = tune_grid(xgb, fmla, resamples = folds2, grid = tune_grid_boost, metrics = metric_set(rmse))
best_params = select_best(tune_res)
final_spec = finalize_model(xgb, best_params)

xgb_final = final_spec %>% fit(formula = fmla, data = train_df)

# =====================СОХРАНЕНИЕ МОДЕЛЕЙ=======================
save(best_lambda, file = "D:/HSE/3 курс/дата саенс/lamb1.Rda")
save(best_lambda2, file = "D:/HSE/3 курс/дата саенс/lamb2.Rda")
save(model1_wf, file = "D:/HSE/3 курс/дата саенс/model1.Rda")
save(model2_wf, file = "D:/HSE/3 курс/дата саенс/model2.Rda")
save(ridge_model, file = "D:/HSE/3 курс/дата саенс/model3.Rda")
save(lasso_model, file = "D:/HSE/3 курс/дата саенс/model4.Rda")
save(rf, file = "D:/HSE/3 курс/дата саенс/model5.Rda")
save(xgb_final, file = "D:/HSE/3 курс/дата саенс/model6.Rda")
