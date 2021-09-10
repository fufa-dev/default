import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/web/item_fav_node.dart';
import 'package:flutter_app/network/dio_web.dart';
import 'package:flutter_app/pages/page_node_topics.dart';

/// @author: wml
/// @date  : 2019/3/30 6:20 PM
/// @email : mxl1989@gmail.com
/// @desc  : 收藏的节点

class FavouriteNodesGrid extends StatefulWidget {
  @override
  _FavouriteNodesGridState createState() => _FavouriteNodesGridState();
}

class _FavouriteNodesGridState extends State<FavouriteNodesGrid> with AutomaticKeepAliveClientMixin {
  Future<List<FavNode>> _future;

  Future<List<FavNode>> getFavNodes() async {
    return await DioWeb.getFavNodes();
  }

  @override
  void initState() {
    super.initState();

    _future = getFavNodes();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<FavNode>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<FavNode>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
            return Center(
              child: Platform.isIOS ? CupertinoActivityIndicator() : CircularProgressIndicator(),
            );
          case ConnectionState.done:
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (snapshot.data.isNotEmpty) {
              return GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 4,
                childAspectRatio: 0.72,
                padding: EdgeInsets.all(8.0),
                children: snapshot.data.map((FavNode node) {
                  return _gridItem(node);
                }).toList(),
              );
            } else {
              // 空视图
              return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                    width: 128.0,
                    height: 114.0,
                    margin: EdgeInsets.only(bottom: 30),
                    child: FlareActor("assets/Broken Heart.flr", animation: "Heart Break", shouldClip: false)),
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  width: 250,
                  child: Text("No Favorites Yet!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.black.withOpacity(0.65),
                      )),
                ),
                Container(
                  width: 270,
                  margin: EdgeInsets.only(bottom: 114),
                  child: Text("Browse to a node and tap on the star icon to save something in this list.",
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 17, height: 1.1, color: Colors.black.withOpacity(0.65))),
                ),
              ]);
            }
        }
        return null; // unreachable
      },
    );
  }

  Widget _gridItem(FavNode node) {
    return InkWell(
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Hero(
              tag: 'node_${node.nodeId}',
              child: CachedNetworkImage(
                imageUrl: node.img,
                fit: BoxFit.fill,
                width: 73,
                height: 73,
                placeholder: (context, url) => Icon(Icons.photo, size: 60.0, color: Colors.grey),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Column(
              children: <Widget>[
                Text(node.nodeName),
                SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.forum,
                      size: 13,
                      color: Colors.grey,
                    ),
                    Text(
                      node.replyCount,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      onTap: () {
        var future = Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NodeTopics(
                      node.nodeId,
                      nodeName: node.nodeName,
                      nodeImg: node.img,
                    )));
        future.then((value) {
          setState(() {
            _future = getFavNodes();
          });
        });
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
