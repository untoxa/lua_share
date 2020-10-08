Библиотека LUA SHARE
====================

Текущие версии предназначены для работы с QUIK 8.5 x64 и выше с поддержкой версии lua 5.3. Если вам необходима 
библиотека для работы с более ранними версиями QUIK, вы можете скачать предыдущий релиз из истории релизов.

Скачать: [текущий релиз для QUIK 8.X x64](https://github.com/untoxa/lua_share/releases/download/latest/lua_share_binaries.zip)
-----------------------------------------

ОПИСАНИЕ:
=========

Библиотека предназначена для обмена данными между lua-скриптами, работающими в разных процессах, а так же в 
одном процессе, но в разных lua-машинах. Прежде всего, она будет полезна пользователям терминала QUIK.

Комплект состоит из библиотеки lua_share.dll и файла lua_share_boot.lua. Для корректной работы оба файла должны 
находиться в одном каталоге. Если файл lua_share_boot.lua отсутствует, то библиотека ведет себя несколько иначе, 
но тоже работает, о чем ниже. Для межпроцессного взаимодействия в комплект так же входит IPC-сервер под названием
lua_share_server.exe, lua-скрипт lua_share_server.lua и rpc-библиотека lua_share_rpc.dll.

инициализация:
--------------

```
package.cpath = getScriptPath() .. "/?.dll"  
sh = require "lua_share"
```

запись и чтение:
----------------

```
sh["hello"] = "world" -- запись  
val = sh["hello"]     -- чтение
```

пространства имен:
------------------

```
local ns = sh.GetNameSpace("test_name_space")  -- создать пространство имен test_name_space  
ns["hello"] = "world" -- запись  
val = ns["hello"]     -- чтение
```

получение снапшота:
-------------------

```
local ns = sh.GetNameSpace("test_name_space")  -- создать пространство имен test_name_space  
ns["hello"] = "hello" -- 1 значение  
ns["world"] = "world" -- 2 значение  
val = ns:DeepCopy() -- получение снапшота
```

"bootstrap":
------------

Файл lua_share_boot.lua содержит код, который кастомизирует поведение хранилища. В текущей реализации 
используется  сравнение таблиц по содержимому. Например:

```
local ns = sh.GetNameSpace("test_name_space")  
ns[{1, 2, {3, 4}}] = "JOHN"  
ns[{1, 2, {3, 4}}] = "DOE"  
tmp = ns[{1, 2, {3, 4}}]
```

Если файл lua_share_boot.lua существует, то в результате хранилище будет содержать только строку 
"DOE" и в переменную tmp будет помещено это значение, иначе хранилице будет содержать обе строки: 
"JOHN" и "DOE", а в переменную tmp будет помещено значение nil, так как ключи {1, 2, {3, 4}} - это 
deepcopy исходных ключей и разные объекты, хотя и с одинаковым содержимым, а по-умолчанию в lua 
сравниваются ссылки.

В lua_share_boot.lua можно запрограммировать свое поведение, а добавить свои метаметоды, например __gc. 
См комментарии в коде lua_share_boot.lua.


IPC:
----

Существует возможность создавать "удаленные" пространства имен, общие для нескольких запущенных приложений 
(терминалов QUIK). Для этого необходимо запустить сервер lua_share_server.exe, который хранит общие данные. 
Сервер запускает lua-скрипт, который хранится в файле lua_share_server.lua и который можно, при желании, 
кастомизировать. Общее хранилище существует, пока запущен сервер. Удаленное пространство имен создается 
следующим образом:

```
local ns = sh.GetIPCNameSpace("test_name_space")
```

Способ работы с ним не отличается.


RPC:
----

Существует возможность вызова удаленной функции на lua_share_server и получить результаты ее выполнения.
Тестовая функция testfunc() определена в lua_share_server.lua. Вот пример ее вызова:

```
local ns = sh.GetIPCNameSpace("test_name_space")  
a, b, c = ns("testfunc", "a", {1, 2, {3, "b"}}) -- просто вызываем IPC неймспейс как функцию
```

pre-defined пространства:
-------------------------

"queues"    - пространство имен, реализующее очереди (queue).
"eventlist" - пространство, реализующее списки событий (аналог waitformultipleobjects).
"permanent" - пространство, загружающее себя из файла при старте и записывающее себя в файл при
              выходе (завершении всех скриптов).


примеры:
--------

Примеры предназначены для запуска в терминале QUIK.

01_test_share_common.lua      - общий пример работы с lua_share

02_test_share_producer.lua    - пример скрипта "писатель" в цикле обновляет общие данные
03_test_share_consumer.lua    - пример скрипта "читатель" читает данные и выводит их в окно сообщений

04_test_share_tablekeys.lua   - демонстрация использования таблиц в качестве ключей хранилища

05_test_share_pushqueue.lua   - очереди: писатель
06_test_share_popqueue.lua    - очерели: читатель

07_test_share_pushevent.lua   - eventlist: писатель
08_test_share_popevent.lua    - eventlist: читатель

09_test_share_permanent.lua   - сохранение данных между запусками скрипта а так же перезапуском QUIK

10_test_share_IPC.lua         - пример работы с "удаленным" хранилищем, должен быть запущен lua_share_server.exe

11_test_share_RPC.lua         - пример удаленного вызова функции, должен быть запущен lua_share_server.exe и
                                в lua_share_server.lua должна быть определена функция  testfunc().
