import 'package:conway_game_of_life/core/saved_blocks.dart';
import 'package:conway_game_of_life/core/view_model/model_board.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SubBlockExplorer extends StatelessWidget {
  const SubBlockExplorer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final ModelBoard model = Provider.of(context, listen: false);
    return ListView.builder(
      itemBuilder: (context, index) {
        final block = listBlocks[index];
        return ListTile(
          onTap: () {
            // model.pause();
          },
          title: Text(block.name),
          subtitle: Text(block.des),
          trailing: Text("${block.cols} X ${block.rows}"),
        );
      },
      itemCount: listBlocks.length,
    );
  }
}
