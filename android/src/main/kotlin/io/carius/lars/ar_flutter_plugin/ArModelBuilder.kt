package io.carius.lars.ar_flutter_plugin

import android.content.Context
import com.google.ar.sceneform.Node
import com.google.ar.sceneform.math.Vector3
import com.google.ar.sceneform.math.Quaternion
import com.google.ar.sceneform.rendering.Color
import com.google.ar.sceneform.rendering.Material
import com.google.ar.sceneform.rendering.MaterialFactory
import com.google.ar.sceneform.rendering.ShapeFactory
import com.google.ar.sceneform.rendering.ModelRenderable
import com.google.ar.sceneform.rendering.RenderableDefinition
import com.google.ar.sceneform.assets.RenderableSource

import java.util.concurrent.CompletableFuture
import android.net.Uri

// Responsible for creating Renderables and Nodes
class ArModelBuilder {

    // Creates feature point node
    fun makeFeaturePointNode(context: Context, xPos: Float, yPos: Float, zPos: Float): Node {
        val featurePoint = Node()                 
        var cubeRenderable: ModelRenderable? = null      
        MaterialFactory.makeOpaqueWithColor(context, Color(android.graphics.Color.YELLOW))
        .thenAccept { material ->
            val vector3 = Vector3(0.01f, 0.01f, 0.01f)
            cubeRenderable = ShapeFactory.makeCube(vector3, Vector3(xPos, yPos, zPos), material)
            cubeRenderable?.isShadowCaster = false
            cubeRenderable?.isShadowReceiver = false
        }
        featurePoint.renderable = cubeRenderable

        return featurePoint
    }

    // Creates a coordinate system model at the world origin (X-axis: red, Y-axis: green, Z-axis:blue)
    // The code for this function is adapted from Alexander's stackoverflow answer (https://stackoverflow.com/questions/48908358/arcore-how-to-display-world-origin-or-axes-in-debug-mode) 
    fun makeWorldOriginNode(context: Context): Node {
        val axisSize = 0.1f
        val axisRadius = 0.005f

        val rootNode = Node()
        val xNode = Node()
        val yNode = Node()
        val zNode = Node()

        rootNode.addChild(xNode)
        rootNode.addChild(yNode)
        rootNode.addChild(zNode)

        xNode.worldPosition = Vector3(axisSize / 2, 0f, 0f)
        xNode.worldRotation = Quaternion.axisAngle(Vector3(0f, 0f, 1f), 90f)

        yNode.worldPosition = Vector3(0f, axisSize / 2, 0f)

        zNode.worldPosition = Vector3(0f, 0f, axisSize / 2)
        zNode.worldRotation = Quaternion.axisAngle(Vector3(1f, 0f, 0f), 90f)

        MaterialFactory.makeOpaqueWithColor(context, Color(255f, 0f, 0f))
                .thenAccept { redMat ->
                    xNode.renderable = ShapeFactory.makeCylinder(axisRadius, axisSize, Vector3.zero(), redMat)
                }

        MaterialFactory.makeOpaqueWithColor(context, Color(axisRadius, 255f, 0f))
                .thenAccept { greenMat ->
                    yNode.renderable = ShapeFactory.makeCylinder(axisRadius, axisSize, Vector3.zero(), greenMat)
                }

        MaterialFactory.makeOpaqueWithColor(context, Color(0f, 0f, 255f))
                .thenAccept { blueMat ->
                    zNode.renderable = ShapeFactory.makeCylinder(axisRadius, axisSize, Vector3.zero(), blueMat)
                }

        return rootNode
    }

    // Creates a node form a given gltf model path or URL. The gltf asset loading in Scenform is asynchronous, so the function returns a compleatable future of type Node
    fun makeNodeFromGltf(context: Context, modelPath: String, worldScale: Vector3, worldPosition: Vector3, worldRotation: Quaternion): CompletableFuture<Node> {
        val completableFutureNode: CompletableFuture<Node> = CompletableFuture<Node>()

        val gltfNode = Node()                 

        ModelRenderable.builder()
        .setSource(context, RenderableSource.builder().setSource(
                context,
                Uri.parse(modelPath),
                RenderableSource.SourceType.GLTF2)
                .build())
        .setRegistryId(modelPath)
        .build()
        .thenAccept{ renderable -> 
            gltfNode.renderable = renderable
            gltfNode.worldScale = worldScale
            gltfNode.worldPosition = worldPosition
            gltfNode.worldRotation = worldRotation
            completableFutureNode.complete(gltfNode)
        }
        .exceptionally({throwable -> 
            completableFutureNode.completeExceptionally(throwable)
            null // return null because java expects void return (in java, void has no instance, whereas in Kotlin, this closure returns a Unit which has one instance)
        })

        return completableFutureNode
    }

    // Creates a node form a given glb model path or URL. The gltf asset loading in Scenform is asynchronous, so the function returns a compleatable future of type Node
    fun makeNodeFromGlb(context: Context, modelPath: String, worldScale: Vector3, worldPosition: Vector3, worldRotation: Quaternion): CompletableFuture<Node> {
        val completableFutureNode: CompletableFuture<Node> = CompletableFuture<Node>()

        val gltfNode = Node()                 

        ModelRenderable.builder()
        .setSource(context, RenderableSource.builder().setSource(
                context,
                Uri.parse(modelPath),
                RenderableSource.SourceType.GLB)
                .build())
        .setRegistryId(modelPath)
        .build()
        .thenAccept{ renderable -> 
            gltfNode.renderable = renderable
            gltfNode.worldScale = worldScale
            gltfNode.worldPosition = worldPosition
            gltfNode.worldRotation = worldRotation
            completableFutureNode.complete(gltfNode)
        }
        .exceptionally({throwable -> 
            completableFutureNode.completeExceptionally(throwable)
            null // return null because java expects void return (in java, void has no instance, whereas in Kotlin, this closure returns a Unit which has one instance)
        })

        return completableFutureNode
    }
}