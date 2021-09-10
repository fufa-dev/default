import 'dart:async';
import 'dart:io';

import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/generated/i18n.dart';
import 'package:flutter_app/models/web/item_profile_recent_reply.dart';
import 'package:flutter_app/network/dio_web.dart';
import 'package:flutter_app/pages/page_profile.dart';

// 用户所有回复列表
class AllRepliesListView extends StatefulWidget {
  final String userName;

  const AllRepliesListView(this.userName);

  @override
  State<StatefulWidget> createState() => TopicListViewState();
}

class TopicListViewState extends State<AllRepliesListView> {
  int p = 1;
  int maxPage = 1;

  bool isLoading = false;
  bool empty = false;
  List<ProfileRecentReplyItem> items = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 获取数据
    getTopics();
    // 监听是否滑到了页面底部
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        print("加载更多...");
        if (items.isNotEmpty && p <= maxPage) {
          getTopics();
        } else {
          print("没有更多...");
          HapticFeedback.heavyImpact(); // 震动反馈
        }
      }
    });
  }

  Future getTopics() async {
    if (!isLoading) {
      isLoading = true;
      List<ProfileRecentReplyItem> newEntries = await DioWeb.getAllReplies(widget.userName, p++);
      setState(() {
        isLoading = false;
        if (newEntries.isNotEmpty) {
          items.addAll(newEntries);
          maxPage = newEntries[0].maxPage;
        } else {
          empty = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isNotEmpty) {
      return RefreshIndicator(
          child: Container(
            child: ListView.separated(
              controller: _scrollController,
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == items.length) {
                  // 滑到了最后一个item
                  return _buildLoadText();
                } else {
                  return ReplyItemView(items[index]);
                }
              },
              separatorBuilder: (BuildContext context, int index) => Divider(
                height: 0,
                indent: 12,
                endIndent: 12,
              ),
            ),
          ),
          onRefresh: _onRefresh);
    } else if (empty == true) {
      // 空视图
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 128.0,
            height: 114.0,
            margin: EdgeInsets.only(bottom: 30),
            child: FlareActor("assets/Broken Heart.flr", animation: "Heart Break", shouldClip: false)),
        Container(
          margin: EdgeInsets.only(bottom: 114),
          width: 250,
          child: Text("No Replies Yet!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: Colors.black.withOpacity(0.65),
              )),
        ),
      ]);
    }
    // By default, show a loading spinner
    return Center(
      child: Platform.isIOS ? CupertinoActivityIndicator() : CircularProgressIndicator(),
    );
  }

  Widget _buildLoadText() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      child: Center(
        child: Text(p <= maxPage ? S.of(context).loadingPage(p.toString()) : "---- 🙄 ----"),
      ),
    );
  }

  //刷新数据,重新设置future就行了
  Future _onRefresh() async {
    print("刷新数据...");
    p = 1;
    List<ProfileRecentReplyItem> newEntries = await DioWeb.getAllReplies(widget.userName, p);
    setState(() {
      items.clear();
      items.addAll(newEntries);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }
}
