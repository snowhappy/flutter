import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_osc_client/constance/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_osc_client/netUtils/net_utils.dart';
import 'package:flutter_osc_client/pages/web_login_page.dart';
import 'package:flutter_osc_client/utils/data_save_utils.dart';
import 'package:flutter_osc_client/utils/event_bus_utils.dart';
import 'package:flutter_osc_client/widgets/new_list_item.dart';

class NewsListPage extends StatefulWidget {
  @override
  _NewsListPageState createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  bool isLogin = false;
  int currentPage = 1;
  List newsList;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scrollController.addListener((){
      var maxScroll = _scrollController.position.maxScrollExtent;  //最大
      var piexls = _scrollController.position.pixels; //当前
      if(maxScroll == piexls){
         currentPage ++;
          Future.delayed(Duration(seconds: 3),(){
            getNewList(true);
          });
      }


    });

    ///判断是会否登录
    DataSaveUtils.isLogin().then((isLogin) {
      if (!mounted) return;
      setState(() {
        this.isLogin = isLogin;
      });
    });

    ///监听登出
    eventBus.on<LogoutEvent>().listen((event) {
      if (!mounted) true;
      setState(() {
        this.isLogin = false;
      });
    });

    //监听登录
    eventBus.on<LoginEvent>().listen((event) {
      if (!mounted) return;
      setState(() {
        this.isLogin = true;
      });
      //登录成功
      getNewList(false);
    });
  }




  @override
  Widget build(BuildContext context) {
    ///没有登录去登录
    if (!isLogin) {
      return Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('由于openApi的限制, 必须登录才获取资讯!'),
              InkWell(
                onTap: _gotoLogin,
                child: Text('去登陆'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
        body: RefreshIndicator(
      child: _buildWidget(),
      onRefresh: _pullToRefresh,
    ));
  }

  Future<Null> _pullToRefresh() async {
    currentPage = 1;
    getNewList(false);
  }

  ///去登陆
  _gotoLogin() async {
    final result = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => LoginWebPage()));

    if (result != null && result == 'refresh') {
      ///登录成功 eventBus 通知
      eventBus.fire(LoginEvent());
    }
  }

  _buildWidget() {
    if (newsList == null) {
      //TODO 获取数据
      getNewList(false);
      return CupertinoActivityIndicator();
    }

    return ListView.builder(
      controller: _scrollController,
      itemBuilder: (contex, index) {
        if (index == newsList.length) {
          ///尾部句
          return Container(
            height: 60.0,

            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[CupertinoActivityIndicator(), Text('上拉加载更多')],
            ),
          );
        }

        return NewsListItem(newsList: newsList[index]);
      },
      itemCount: newsList.length + 1,

    );
  }

  ///加载数据
  getNewList(bool isLoadMore) {
    DataSaveUtils.isLogin().then(((isLogin) {
      if (isLogin) {
        DataSaveUtils.getAccessToken().then((accessToken) {
          if (accessToken != null && accessToken.length > 0) {
            Map<String, dynamic> params = Map();
            params['access_token'] = accessToken;
            params['catalog'] = 1;
            params['page'] = currentPage;
            params['pageSize'] = 20;
            params['dataType'] = 'json';

            NetUtils.get(AppUrls.NEWS_LIST, params).then((data) {
              if (data != null && data.length > 0) {
                Map<String, dynamic> requestInfo = json.decode(data);
                List _newsList;
                _newsList = requestInfo['newslist'];
                setState(() {
                  if (!mounted) return;
                  if (isLoadMore) {
                    newsList.addAll(_newsList);
                  } else {
                    newsList = _newsList;
                  }
                });
              }
            });
          }
        });
      }
    }));
  }
}
