using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Timeline;

namespace CustomTimeLine
{
    [TrackClipType(typeof(MyTineClip))] // 表明这个轨道接受MySkyboxAsset类型的片段
    [TrackBindingType(typeof(Material))] // 表明这个轨道可以绑定到一个Material类型的对象
    public class MyTimeLineTrack : TrackAsset
    {
        
    }
}

